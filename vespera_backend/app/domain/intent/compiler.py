"""Intent compiler v0 — VSP-010.

Converts free-text listening requests into a validated CompiledIntent.

Pipeline:
  1. Build a strict system prompt that forbids track-name invention.
  2. Call the LLM provider (Groq or deterministic fallback).
  3. Parse and validate JSON output with Pydantic.
  4. Reject or flag invalid / ambiguous fields.
  5. Return CompiledIntent with all unknown constraints surfaced.

The LLM is treated as untrusted input.  Its JSON is fully validated
before any downstream tool is called.
"""

from __future__ import annotations

import json
import logging
import re
from functools import lru_cache

from app.domain.intent.llm_interface import DeterministicProvider, GroqProvider, LLMProvider
from app.schemas.intent import CompiledIntent

log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# System prompt
# ---------------------------------------------------------------------------

_SYSTEM_PROMPT = """\
You are the Vespera intent compiler.  Your job is to convert a listener's \
natural-language music request into a strict JSON policy object.

RULES:
1. Return ONLY a valid JSON object — no prose, no markdown, no code fences.
2. Do NOT invent track titles, artist names, or album names.
3. Preserve negations exactly: "no vocals" sets require_instrumental=true; \
"not hip hop tonight" sets excluded_genres=["hip hop"] AND scope="current_session".
4. Separate scope: "just for tonight" → scope="current_session", \
"never recommend this artist again" → scope="global_explicit_rule".
5. If you cannot parse a hard constraint, add it to ambiguities[].
6. search_keywords must be 2–6 generic catalog-safe words (genres, moods, \
instruments) — never track titles.
7. confidence is your self-assessed 0.0–1.0 certainty you interpreted correctly.

OUTPUT SCHEMA (all fields required):
{
  "goal": "<80-char human-readable goal>",
  "scope": "current_session" | "context" | "global_explicit_rule",
  "memory_action": "session_only" | "update_context" | "confirm_global",
  "duration_min": <integer minutes or null>,
  "require_instrumental": <true | false | null>,
  "exclude_explicit": <true | false>,
  "excluded_artists": [],
  "excluded_genres": [],
  "required_languages": [],
  "max_artist_repeats": <integer or null>,
  "preferred_genres": [],
  "preferred_artists": [],
  "energy": "low" | "medium" | "high" | "any",
  "search_keywords": [],
  "novelty": "familiar" | "mixed" | "adventurous" | "any",
  "confidence": <0.0–1.0>,
  "ambiguities": [],
  "unverified_constraints": [],
  "negations_detected": []
}
"""

# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------

_SAFE_STRING_RE = re.compile(r"^[a-zA-Z0-9 ',&.\-+/()àáâãäåæçèéêëìíîïðñòóôõöùúûüýþÿ]+$")
_MAX_LIST_ITEMS = 10


def _sanitise_string(value: object, max_len: int = 120) -> str | None:
    if not isinstance(value, str):
        return None
    v = value.strip()[:max_len]
    # Strip anything that looks like a prompt-injection attempt
    if any(c in v for c in ("<", ">", "{", "}", "\\", "\n", "\r")):
        return None
    return v or None


def _sanitise_string_list(value: object, max_len: int = 40) -> list[str]:
    if not isinstance(value, list):
        return []
    result = []
    for item in value[:_MAX_LIST_ITEMS]:
        s = _sanitise_string(item, max_len)
        if s:
            result.append(s)
    return result


def _clamp_float(value: object, lo: float, hi: float, default: float) -> float:
    try:
        return max(lo, min(hi, float(value)))  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return default


# ---------------------------------------------------------------------------
# Compiler
# ---------------------------------------------------------------------------

class IntentCompiler:
    """Compile free text into a validated CompiledIntent.

    ``provider`` is injected; pass None to auto-select (Groq if key
    available, deterministic otherwise).
    """

    def __init__(self, provider: LLMProvider | None = None) -> None:
        self._provider = provider or _default_provider()

    def compile(self, text: str) -> CompiledIntent:
        """Return a CompiledIntent for ``text``.

        Never raises — if the LLM fails or returns unparseable JSON,
        falls back to the deterministic provider and sets confidence=0.
        """
        text = text.strip()
        if not text:
            return CompiledIntent(
                goal="Music",
                search_keywords=[],
                ambiguities=["Empty request — please describe what you want to listen to."],
                confidence=0.0,
            )

        raw_json = self._call_provider(text)
        return self._parse_and_validate(raw_json, original_text=text)

    # ── private ──────────────────────────────────────────────────────────────

    def _call_provider(self, text: str) -> str:
        try:
            return self._provider.complete_json(_SYSTEM_PROMPT, text)
        except Exception as exc:
            log.warning("Primary LLM provider failed (%s); using deterministic fallback.", exc)
            fallback = DeterministicProvider()
            return fallback.complete_json(_SYSTEM_PROMPT, text)

    def _parse_and_validate(self, raw: str, original_text: str) -> CompiledIntent:
        try:
            data = json.loads(raw)
        except (json.JSONDecodeError, ValueError) as exc:
            log.warning("Intent JSON parse failed: %s — raw: %.200s", exc, raw)
            fallback = DeterministicProvider()
            raw2 = fallback.complete_json(_SYSTEM_PROMPT, original_text)
            try:
                data = json.loads(raw2)
            except Exception:
                return CompiledIntent(
                    goal="Music",
                    search_keywords=[],
                    confidence=0.0,
                    ambiguities=["Could not parse your request — please rephrase."],
                )

        # Sanitise every field before touching Pydantic
        goal = _sanitise_string(data.get("goal"), 80) or "Music"
        scope_raw = str(data.get("scope", "current_session"))
        memory_raw = str(data.get("memory_action", "session_only"))

        # duration_min — accept int or coercible string
        try:
            dm = int(data.get("duration_min") or 0) or None
            if dm and not (1 <= dm <= 180):
                dm = None
        except (TypeError, ValueError):
            dm = None

        # require_instrumental — accept bool, None, or truthful strings
        ri_raw = data.get("require_instrumental")
        require_instrumental: bool | None = None
        if isinstance(ri_raw, bool):
            require_instrumental = ri_raw
        elif isinstance(ri_raw, str):
            require_instrumental = ri_raw.lower() in ("true", "yes", "1") or None

        confidence = _clamp_float(data.get("confidence"), 0.0, 1.0, 0.5)
        energy_raw = str(data.get("energy", "any")).lower()
        novelty_raw = str(data.get("novelty", "any")).lower()

        try:
            intent = CompiledIntent(
                goal=goal,
                scope=scope_raw,
                memory_action=memory_raw,
                duration_min=dm,
                require_instrumental=require_instrumental,
                exclude_explicit=bool(data.get("exclude_explicit", False)),
                excluded_artists=_sanitise_string_list(data.get("excluded_artists")),
                excluded_genres=_sanitise_string_list(data.get("excluded_genres")),
                required_languages=_sanitise_string_list(data.get("required_languages")),
                max_artist_repeats=_safe_int(data.get("max_artist_repeats"), 1, 10),
                preferred_genres=_sanitise_string_list(data.get("preferred_genres")),
                preferred_artists=_sanitise_string_list(data.get("preferred_artists")),
                energy=energy_raw if energy_raw in ("low", "medium", "high", "any") else "any",
                novelty=novelty_raw if novelty_raw in ("familiar", "mixed", "adventurous", "any") else "any",
                search_keywords=_sanitise_string_list(data.get("search_keywords"), 40)[:6],
                confidence=confidence,
                ambiguities=_sanitise_string_list(data.get("ambiguities"), 120),
                unverified_constraints=_sanitise_string_list(data.get("unverified_constraints"), 120),
                negations_detected=_sanitise_string_list(data.get("negations_detected"), 80),
            )
        except Exception as exc:
            log.warning("CompiledIntent validation failed: %s", exc)
            intent = CompiledIntent(
                goal=goal,
                search_keywords=_sanitise_string_list(data.get("search_keywords"), 40)[:6],
                confidence=0.3,
                ambiguities=[f"Some intent fields could not be validated: {exc}"],
            )

        return intent


def _safe_int(value: object, lo: int, hi: int) -> int | None:
    try:
        v = int(value)  # type: ignore[arg-type]
        return v if lo <= v <= hi else None
    except (TypeError, ValueError):
        return None


@lru_cache(maxsize=1)
def _default_provider() -> LLMProvider:
    """Return Groq if a key is configured, deterministic fallback otherwise."""
    from app.config import settings
    if settings.GROQ_API_KEY:
        return GroqProvider()
    return DeterministicProvider()

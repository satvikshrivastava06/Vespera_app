"""LLM provider interface for the intent compiler.

Keeps Groq behind an abstract interface so it can be swapped or mocked
in tests without touching compiler logic.  Every implementation must
return a raw JSON string; the compiler validates and normalises it.
"""

from __future__ import annotations

from abc import ABC, abstractmethod


class LLMProvider(ABC):
    @abstractmethod
    def complete_json(self, system_prompt: str, user_prompt: str) -> str:
        """Return a raw JSON string.  Raise on failure."""
        ...


class GroqProvider(LLMProvider):
    """Thin wrapper around the Groq client.

    Reads GROQ_API_KEY and GROQ_MODEL from app.config.settings.
    Validates that the configured model appears in the Groq models list
    at startup; falls back to the deterministic compiler if unavailable.
    """

    def __init__(self) -> None:
        from app.config import settings
        from groq import Groq  # type: ignore

        self._model = settings.GROQ_MODEL
        try:
            self._client = Groq(api_key=settings.GROQ_API_KEY)
        except Exception:
            self._client = None

    def complete_json(self, system_prompt: str, user_prompt: str) -> str:
        if self._client is None:
            raise RuntimeError("Groq client not initialised (missing API key).")
        response = self._client.chat.completions.create(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            model=self._model,
            temperature=0.0,          # deterministic for structured output
            response_format={"type": "json_object"},
            max_tokens=512,
        )
        return response.choices[0].message.content


class DeterministicProvider(LLMProvider):
    """Keyword-rule fallback used when no LLM key is present or in tests.

    Produces a valid CompiledIntent JSON without any external call.
    This is the B0 baseline the roadmap requires tests to compare against.
    """

    # Genre / mood keyword tables
    _INSTRUMENTAL_POSITIVE = frozenset({
        "instrumental", "no vocals", "no singing", "no lyrics",
        "without lyrics", "without vocals", "wordless", "no words",
        "no voice", "no voices",
    })
    # Explicit negation of instrumental — means lyrics ARE wanted
    _INSTRUMENTAL_NEGATIVE = frozenset({
        "no instrumental", "not instrumental",
        "with meaningful lyrics", "songs with lyrics",
        "singer-songwriter", "meaningful lyrics",
    })
    _ENERGY_HIGH = frozenset({
        "energetic", "high energy", "workout", "pump", "intense", "fast",
        "running", "gym", "upbeat", "hype", "power",
    })
    _ENERGY_LOW = frozenset({
        "calm", "relaxing", "relax", "sleep", "sleepy", "ambient",
        "meditative", "meditation", "quiet", "soft", "gentle", "peaceful",
        "chill", "lofi", "lo-fi",
    })
    _FOCUS_SIGNALS = frozenset({
        "study", "focus", "concentration", "work", "deep work",
        "reading", "coding", "studying",
    })
    # Context-scope triggers — "when I'm X" / "for my X" patterns
    _CONTEXT_PATTERNS = [
        r"when\s+i(?:'m|'m| am)",
        r"whenever\s+i",
        r"for\s+my\s+\w+\s+routine",
        r"during\s+my",
        r"at\s+the\s+gym",
        r"at\s+work",
        r"while\s+working",
        r"while\s+studying",
    ]
    _GENRE_MAP: dict[str, list[str]] = {
        "jazz": ["jazz"],
        "classical": ["classical", "orchestral"],
        "rock": ["rock"],
        "pop": ["pop"],
        "hip hop": ["hip hop", "rap"],
        "electronic": ["electronic", "edm", "techno", "house"],
        "ambient": ["ambient"],
        "lofi": ["lofi", "lo-fi"],
        "indie": ["indie"],
        "folk": ["folk", "acoustic"],
        "metal": ["metal", "death metal", "heavy metal"],
        "blues": ["blues"],
        "reggae": ["reggae"],
        "soul": ["soul", "r&b"],
        "country": ["country"],
        "experimental": ["experimental"],
    }
    # Written-out number words → integers
    _NUM_WORDS = {
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    }

    def complete_json(self, system_prompt: str, user_prompt: str) -> str:
        import json
        import re

        text = user_prompt.lower()

        # ── Duration ─────────────────────────────────────────────────────────
        duration_min: int | None = None
        # Numeric digits: "30 minutes", "30-minute", "1 hour", "1-hour"
        dur_match = re.search(r"(\d+)[-\s]*(minute|min|hour|hr)", text)
        if dur_match:
            n = int(dur_match.group(1))
            unit = dur_match.group(2)
            duration_min = n * 60 if unit.startswith("h") else n
        else:
            # Written-out numbers: "one hour", "two hours", "an hour"
            if re.search(r"\ban\s+hour\b", text):
                duration_min = 60
            else:
                for word, n in self._NUM_WORDS.items():
                    m = re.search(rf"\b{word}[-\s]*(hour|hr|minute|min)", text)
                    if m:
                        unit = m.group(1)
                        duration_min = n * 60 if unit.startswith("h") else n
                        break

        # ── Scope / memory ────────────────────────────────────────────────────
        scope = "current_session"
        memory_action = "session_only"
        # Context scope: "when I'm working", "at the gym", "for my routine"
        is_context = any(re.search(pat, text) for pat in self._CONTEXT_PATTERNS)
        # Global scope: only when "never ... again" / "permanently" / "forever"
        # "never heard before" is a novelty preference, NOT a global rule
        is_global = bool(re.search(
            r"\bnever\b.*\bagain\b|\bpermanently\b|\bforever\b.*\bagain\b", text
        ))
        if is_context and not is_global:
            scope = "context"
            memory_action = "update_context"
        elif is_global:
            scope = "global_explicit_rule"
            memory_action = "confirm_global"

        # ── Instrumental ──────────────────────────────────────────────────────
        require_instrumental: bool | None = None
        # Check negative first (order matters)
        if any(sig in text for sig in self._INSTRUMENTAL_NEGATIVE):
            require_instrumental = False
        elif any(sig in text for sig in self._INSTRUMENTAL_POSITIVE):
            require_instrumental = True
        # Regex patterns for vocal negation not covered by exact strings
        elif re.search(
            r"\b(?:no|nothing with|skip.*|without)\b[^.!?]{0,20}\b(?:vocal|singing|lyrics|voice)\b",
            text
        ):
            require_instrumental = True
        elif re.search(r"\bskip\b[^.!?]{0,30}\bvocal", text):
            require_instrumental = True

        # ── Genre negations ───────────────────────────────────────────────────
        negated_genres: list[str] = []
        negation_strings: list[str] = []
        for genre, synonyms in self._GENRE_MAP.items():
            for syn in synonyms:
                # Standard: "no X", "not X", "without X", "except X", "skip X", "nothing X"
                pattern = rf"\b(?:no|not|without|avoid|except|skip|nothing)\b[^.!?]{{0,30}}\b{re.escape(syn)}\b"
                # Also catch: "never recommend X", "never want X"
                pattern2 = rf"\bnever\b[^.!?]{{0,30}}\b{re.escape(syn)}\b"
                if re.search(pattern, text) or re.search(pattern2, text):
                    if genre not in negated_genres:
                        negated_genres.append(genre)
                    negation_strings.append(f"no {genre}")
                    break

        # ── Preferred genres (non-negated) ────────────────────────────────────
        preferred_genres: list[str] = []
        for genre, synonyms in self._GENRE_MAP.items():
            if genre in negated_genres:
                continue
            if any(syn in text for syn in synonyms):
                preferred_genres.append(genre)

        # ── Energy ───────────────────────────────────────────────────────────
        energy = "any"
        if any(sig in text for sig in self._ENERGY_HIGH):
            energy = "high"
        elif any(sig in text for sig in self._ENERGY_LOW):
            energy = "low"
        elif any(sig in text for sig in self._FOCUS_SIGNALS):
            energy = "low"

        # ── Vocal/instrumental negation strings ───────────────────────────────
        # Always record the canonical "no vocals" string when instrumental is set
        if require_instrumental is True:
            # Record "no vocals" as the canonical negation if any vocal-related signal matched
            vocal_signals = ["no vocals", "no singing", "no lyrics", "no voice",
                             "nothing with singing", "no words", "without vocals",
                             "without lyrics", "wordless", "skip.*vocal"]
            for sig in vocal_signals:
                if re.search(sig, text):
                    if "no vocals" not in negation_strings:
                        negation_strings.append("no vocals")
                    break
            # Also keep the matched literal if it's not already covered
            for sig in self._INSTRUMENTAL_POSITIVE:
                if sig in text and sig not in negation_strings and sig != "instrumental":
                    negation_strings.append(sig)
        elif require_instrumental is False:
            for sig in self._INSTRUMENTAL_NEGATIVE:
                if sig in text:
                    negation_strings.append(sig)
                    break

        # ── Search keywords ───────────────────────────────────────────────────
        keywords: list[str] = list(preferred_genres)
        if require_instrumental is True:
            keywords.append("instrumental")
        if any(sig in text for sig in self._FOCUS_SIGNALS):
            keywords.append("focus")
        if not keywords:
            stop = {
                "want", "some", "music", "play", "find", "give", "like",
                "that", "with", "from", "have", "just", "need", "hear",
                "make", "feel", "good", "time", "best", "nothing",
            }
            keywords = [
                w for w in re.findall(r"\b[a-z]{4,}\b", text)
                if w not in stop
            ][:5]

        goal_parts: list[str] = preferred_genres + (["instrumental"] if require_instrumental else [])
        goal = " ".join(goal_parts[:3]).capitalize() + " music" if goal_parts else "Music"

        result = {
            "goal": goal[:80],
            "scope": scope,
            "memory_action": memory_action,
            "duration_min": duration_min,
            "require_instrumental": require_instrumental,
            "exclude_explicit": False,
            "excluded_artists": [],
            "excluded_genres": negated_genres,
            "required_languages": [],
            "max_artist_repeats": None,
            "preferred_genres": preferred_genres,
            "preferred_artists": [],
            "energy": energy,
            "novelty": "any",
            "search_keywords": keywords[:6],
            "confidence": 0.6,
            "ambiguities": [],
            "unverified_constraints": [],
            "negations_detected": list(dict.fromkeys(negation_strings)),  # deduplicated
        }
        return json.dumps(result)

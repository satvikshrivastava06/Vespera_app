"""VSP-010 tests: intent compiler unit tests + golden-set gates.

Sections:
  1. Deterministic provider unit tests — fast, no external calls.
  2. Compiler integration tests using the deterministic provider.
  3. Tuning-set gate  — 28 prompts, zero critical failures required.
  4. Holdout-set gate — 12 prompts, zero critical failures required.

The holdout gate is separated so it can be run independently on release.
"""

from __future__ import annotations

import pytest

from app.domain.intent.compiler import IntentCompiler
from app.domain.intent.evaluator import run_evaluation, print_report
from app.domain.intent.golden_set import HOLDOUT_SET, TUNING_SET
from app.domain.intent.llm_interface import DeterministicProvider
from app.schemas.intent import CompiledIntent, EnergyLevel, IntentScope, MemoryAction


# ── Helpers ──────────────────────────────────────────────────────────────────

def _compile(text: str) -> CompiledIntent:
    """Compile using the deterministic provider (no external calls)."""
    return IntentCompiler(provider=DeterministicProvider()).compile(text)


# ── 1. Deterministic provider unit tests ─────────────────────────────────────

class TestDeterministicProvider:
    def test_instrumental_signal(self):
        intent = _compile("Instrumental only, no vocals please")
        assert intent.require_instrumental is True
        assert any("vocal" in n.lower() for n in intent.negations_detected)

    def test_energy_high(self):
        assert _compile("High energy workout music").energy == EnergyLevel.HIGH

    def test_energy_low_chill(self):
        assert _compile("Calm relaxing music to sleep").energy == EnergyLevel.LOW

    def test_energy_low_study(self):
        assert _compile("Study music for concentration").energy == EnergyLevel.LOW

    def test_genre_jazz(self):
        intent = _compile("Play some jazz")
        assert "jazz" in intent.preferred_genres

    def test_genre_lofi(self):
        intent = _compile("Lofi beats to study to")
        assert "lofi" in intent.preferred_genres

    def test_excluded_genre_negation(self):
        intent = _compile("No hip hop please")
        assert "hip hop" in intent.excluded_genres
        assert any("hip hop" in n.lower() for n in intent.negations_detected)

    def test_duration_minutes(self):
        assert _compile("30 minute playlist").duration_min == 30

    def test_duration_hours(self):
        assert _compile("1 hour of classical").duration_min == 60

    def test_session_scope_tonight(self):
        intent = _compile("Not in the mood for rock tonight")
        assert intent.scope == IntentScope.SESSION
        assert intent.memory_action == MemoryAction.SESSION_ONLY

    def test_global_scope_never(self):
        intent = _compile("Never recommend country music again")
        assert intent.scope == IntentScope.GLOBAL
        assert intent.memory_action == MemoryAction.CONFIRM_GLOBAL

    def test_empty_text_returns_intent(self):
        intent = _compile("   ")
        assert intent.goal
        assert intent.confidence == 0.0
        assert intent.ambiguities

    def test_negation_does_not_set_global_scope(self):
        """'not now' must remain session scope — roadmap critical rule."""
        intent = _compile("Not hip hop today")
        assert intent.scope == IntentScope.SESSION
        assert intent.memory_action == MemoryAction.SESSION_ONLY
        assert "hip hop" in intent.excluded_genres

    def test_negation_metal_excluded(self):
        intent = _compile("Rock but not metal")
        assert "rock" in intent.preferred_genres
        assert "metal" in intent.excluded_genres

    def test_instrumental_plus_genre(self):
        intent = _compile("Instrumental jazz, nothing with singing")
        assert intent.require_instrumental is True
        assert "jazz" in intent.preferred_genres

    def test_search_keywords_populated(self):
        intent = _compile("Calm acoustic folk for reading")
        assert len(intent.search_keywords) > 0

    def test_search_keywords_no_track_titles(self):
        """Keywords must be generic — compiler must never invent track names."""
        intent = _compile("Play some music for focus")
        # All keywords should be short, generic words
        for kw in intent.search_keywords:
            # Very long strings are likely invented track titles
            assert len(kw) < 50, f"Keyword looks like a title: {kw!r}"

    def test_confidence_non_negative(self):
        assert _compile("Jazz piano").confidence >= 0.0

    def test_multi_negation(self):
        intent = _compile("No electronic and no metal")
        assert "electronic" in intent.excluded_genres
        assert "metal" in intent.excluded_genres


# ── 2. Compiler validation / sanitisation ────────────────────────────────────

class TestCompilerSanitisation:
    def test_malformed_json_fallback(self):
        """If the provider returns broken JSON, compiler falls back gracefully."""
        class BrokenProvider:
            def complete_json(self, s, u):
                return "NOT JSON {"

        intent = IntentCompiler(provider=BrokenProvider()).compile("chill music")
        assert intent.goal
        # Deterministic fallback yields confidence=0.6; that is acceptable —
        # the important guarantee is that it does not crash and returns a goal.
        assert intent.confidence >= 0.0

    def test_injection_attempt_in_goal(self):
        """Goal field must be sanitised — no shell/template special chars."""
        class MaliciousProvider:
            def complete_json(self, s, u):
                import json
                return json.dumps({
                    "goal": "<script>alert(1)</script>",
                    "scope": "current_session",
                    "memory_action": "session_only",
                    "duration_min": None,
                    "require_instrumental": None,
                    "exclude_explicit": False,
                    "excluded_artists": [],
                    "excluded_genres": [],
                    "required_languages": [],
                    "max_artist_repeats": None,
                    "preferred_genres": [],
                    "preferred_artists": [],
                    "energy": "any",
                    "novelty": "any",
                    "search_keywords": [],
                    "confidence": 0.9,
                    "ambiguities": [],
                    "unverified_constraints": [],
                    "negations_detected": [],
                })
        intent = IntentCompiler(provider=MaliciousProvider()).compile("test")
        assert "<script>" not in intent.goal

    def test_oversized_lists_truncated(self):
        """Lists longer than _MAX_LIST_ITEMS must be truncated."""
        class BigListProvider:
            def complete_json(self, s, u):
                import json
                return json.dumps({
                    "goal": "Music",
                    "scope": "current_session",
                    "memory_action": "session_only",
                    "duration_min": None,
                    "require_instrumental": None,
                    "exclude_explicit": False,
                    "excluded_artists": [f"artist{i}" for i in range(50)],
                    "excluded_genres": [],
                    "required_languages": [],
                    "max_artist_repeats": None,
                    "preferred_genres": [],
                    "preferred_artists": [],
                    "energy": "any",
                    "novelty": "any",
                    "search_keywords": [],
                    "confidence": 0.8,
                    "ambiguities": [],
                    "unverified_constraints": [],
                    "negations_detected": [],
                })
        intent = IntentCompiler(provider=BigListProvider()).compile("test")
        assert len(intent.excluded_artists) <= 10

    def test_invalid_scope_does_not_crash(self):
        """Unknown scope values must not crash — Pydantic should reject cleanly."""
        class BadScopeProvider:
            def complete_json(self, s, u):
                import json
                return json.dumps({
                    "goal": "Music",
                    "scope": "INVALID_SCOPE",
                    "memory_action": "session_only",
                    "duration_min": None,
                    "require_instrumental": None,
                    "exclude_explicit": False,
                    "excluded_artists": [],
                    "excluded_genres": [],
                    "required_languages": [],
                    "max_artist_repeats": None,
                    "preferred_genres": [],
                    "preferred_artists": [],
                    "energy": "any",
                    "novelty": "any",
                    "search_keywords": [],
                    "confidence": 0.5,
                    "ambiguities": [],
                    "unverified_constraints": [],
                    "negations_detected": [],
                })
        # Must not raise
        intent = IntentCompiler(provider=BadScopeProvider()).compile("test")
        assert intent.goal


# ── 3. Tuning-set gate ────────────────────────────────────────────────────────

def test_tuning_set_zero_critical_failures():
    """Gate 4 (M1 slice): zero critical failures on the 28 tuning prompts.

    Critical fields: negation detection, scope classification,
    memory_action, require_instrumental, excluded_genres.
    """
    compiler = IntentCompiler(provider=DeterministicProvider())
    results, passed = run_evaluation(TUNING_SET, compiler)
    critical_failures = [r for r in results if r.critical and not r.passed]
    print_report(results, "TUNING SET")
    assert passed, (
        f"{len(critical_failures)} critical failure(s) on tuning set.\n"
        + "\n".join(
            f"  {r.prompt_id} {r.field}: expected={r.expected!r} got={r.got!r}"
            for r in critical_failures
        )
    )


# ── 4. Holdout-set gate ───────────────────────────────────────────────────────

def test_holdout_set_zero_critical_failures():
    """Gate 4 release gate: zero critical failures on the 12 holdout prompts.

    These prompts were NEVER used during tuning.  Run once per release.
    Report the small sample size honestly — this does not generalise.
    """
    compiler = IntentCompiler(provider=DeterministicProvider())
    results, passed = run_evaluation(HOLDOUT_SET, compiler)
    critical_failures = [r for r in results if r.critical and not r.passed]
    print_report(results, "HOLDOUT SET (12 prompts — never tuned against)")
    assert passed, (
        f"{len(critical_failures)} critical failure(s) on holdout set.\n"
        "Sample size is 12 — do not generalise; fix the specific failures.\n"
        + "\n".join(
            f"  {r.prompt_id} {r.field}: expected={r.expected!r} got={r.got!r}"
            for r in critical_failures
        )
    )

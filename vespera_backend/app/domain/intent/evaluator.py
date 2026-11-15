"""Golden-set evaluator for the intent compiler (VSP-010).

Usage (from vespera_backend/):
    python -m app.domain.intent.evaluator --set tuning
    python -m app.domain.intent.evaluator --set holdout

The holdout set must ONLY be run to report accuracy, never to tune rules.
Critical-field failures (negation, scope) are reported separately and
cause a non-zero exit code.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass

from app.domain.intent.compiler import IntentCompiler
from app.domain.intent.golden_set import HOLDOUT_SET, TUNING_SET, GoldenPrompt
from app.schemas.intent import CompiledIntent


@dataclass
class FieldResult:
    prompt_id: str
    field: str
    expected: object
    got: object
    passed: bool
    critical: bool


def _check(prompt: GoldenPrompt, intent: CompiledIntent) -> list[FieldResult]:
    results: list[FieldResult] = []

    def _add(field: str, expected: object, got: object, critical: bool = False) -> None:
        if expected is None:
            return  # not checked
        results.append(FieldResult(
            prompt_id=prompt.id,
            field=field,
            expected=expected,
            got=got,
            passed=_matches(expected, got),
            critical=critical or prompt.critical,
        ))

    _add("scope", prompt.expected_scope, intent.scope.value if intent.scope else None, critical=True)
    _add("memory_action", prompt.expected_memory_action, intent.memory_action.value if intent.memory_action else None, critical=True)
    _add("require_instrumental", prompt.expected_require_instrumental, intent.require_instrumental, critical=True)
    _add("energy", prompt.expected_energy, intent.energy.value if intent.energy else None)
    _add("duration_min", prompt.expected_duration_min, intent.duration_min)
    _add("ambiguities_raised",
         True if prompt.expected_ambiguities_raised else None,
         bool(intent.ambiguities))

    # Preferred genres: all expected genres must appear
    if prompt.expected_preferred_genres:
        for genre in prompt.expected_preferred_genres:
            got_genres = [g.lower() for g in intent.preferred_genres]
            found = any(genre.lower() in g for g in got_genres)
            results.append(FieldResult(
                prompt_id=prompt.id,
                field=f"preferred_genres[{genre}]",
                expected=genre,
                got=intent.preferred_genres,
                passed=found,
                critical=False,
            ))

    # Excluded genres: all expected exclusions must appear
    if prompt.expected_excluded_genres:
        for genre in prompt.expected_excluded_genres:
            got_excl = [g.lower() for g in intent.excluded_genres]
            found = any(genre.lower() in g for g in got_excl)
            results.append(FieldResult(
                prompt_id=prompt.id,
                field=f"excluded_genres[{genre}]",
                expected=genre,
                got=intent.excluded_genres,
                passed=found,
                critical=True,  # exclusions are hard constraints
            ))

    # Negations detected: expected substrings must appear
    if prompt.expected_negations_contains:
        for neg in prompt.expected_negations_contains:
            neg_lower = neg.lower()
            detected_lower = [n.lower() for n in intent.negations_detected]
            found = any(neg_lower in d for d in detected_lower)
            results.append(FieldResult(
                prompt_id=prompt.id,
                field=f"negations_detected[{neg}]",
                expected=neg,
                got=intent.negations_detected,
                passed=found,
                critical=True,
            ))

    return results


def _matches(expected: object, got: object) -> bool:
    if expected is None:
        return True
    if isinstance(expected, bool):
        return got is expected
    if isinstance(expected, int):
        return got == expected
    if isinstance(expected, str):
        return str(got).lower() == expected.lower()
    return expected == got


def run_evaluation(prompts: list[GoldenPrompt], compiler: IntentCompiler) -> tuple[list[FieldResult], bool]:
    all_results: list[FieldResult] = []
    for prompt in prompts:
        intent = compiler.compile(prompt.text)
        results = _check(prompt, intent)
        all_results.extend(results)
    critical_failures = [r for r in all_results if r.critical and not r.passed]
    return all_results, len(critical_failures) == 0


def print_report(results: list[FieldResult], label: str) -> None:
    total = len(results)
    passed = sum(1 for r in results if r.passed)
    failed = [r for r in results if not r.passed]
    critical_failures = [r for r in failed if r.critical]

    print(f"\n{'='*60}")
    print(f"Intent compiler evaluation — {label}")
    print(f"{'='*60}")
    print(f"Checks : {total}  |  Passed : {passed}  |  Failed : {len(failed)}")
    print(f"Critical failures : {len(critical_failures)}")

    if failed:
        print("\nFailed checks:")
        for r in failed:
            crit = "  [CRITICAL]" if r.critical else ""
            print(f"  {r.prompt_id:4s}  {r.field:40s}  expected={r.expected!r:30}  got={r.got!r}{crit}")

    if not critical_failures:
        print("\n✓ Zero critical failures — gate passes.")
    else:
        print(f"\n✗ {len(critical_failures)} critical failure(s) — gate BLOCKED.")

    print()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate intent compiler")
    parser.add_argument("--set", choices=["tuning", "holdout", "all"], default="tuning")
    args = parser.parse_args()

    compiler = IntentCompiler()

    if args.set in ("tuning", "all"):
        results, ok = run_evaluation(TUNING_SET, compiler)
        print_report(results, "TUNING SET (28 prompts)")
        if not ok:
            sys.exit(1)

    if args.set in ("holdout", "all"):
        results, ok = run_evaluation(HOLDOUT_SET, compiler)
        print_report(results, "HOLDOUT SET (12 prompts)")
        if not ok:
            sys.exit(1)

# ADR-002: Warm start and familiarity semantics

- Status: Accepted
- Date: 2026-11-15
- Tickets: VSP-001, VSP-012

## Context

H2 and the acceptance scenario ask for “familiar” music in the first 10 minutes. A new install has no listening history, and listeners have no history with an independent CC catalog. Inventing a Music DNA history would repeat the fabricated-content failure mode.

## Decision

1. Familiarity in Milestone 1 is a **seed-neighborhood proxy**, not known listening history.
2. The only seed UI is the contract-summary bottom sheet: the listener picks **3–5 tracks** from the 50–100 track M1 catalog. No extra screen.
3. For the first **600_000 ms** of planned `playable_ms`, the planner prefers tracks that share an artist or Jamendo tag neighborhood with those seeds, or tracks already played in the current session.
4. After that boundary, the planner introduces artists outside the seed neighborhood when eligible candidates exist. If coverage is insufficient, the API returns an explicit unsatisfied-contract result. It does not silently relax quotas.
5. UI and recommendation traces must say **seed-based proxy**, never “songs you know” or “your history.”
6. Any demo/scripted profile or events carry `synthetic = true`. Music DNA is deferred; synthetic evidence is never shown as real listener analytics.
7. Baseline B0 is Jamendo tag/keyword matching, not popularity. The seed catalog has no platform popularity signal.

## Consequences

- Gate 3 events can exist without claiming durable taste.
- The skip-reason replan must not promote a session “not this” into global preference.
- Planner tests should include random 3–5 seed sets and require a ready queue or an explicit unsatisfied result, never a crash or a quiet quota change.

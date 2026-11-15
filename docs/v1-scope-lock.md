# Vespera Milestone 1 scope lock

- Date: 2026-11-15
- Controlling plan: `Vespera_Engineering_Roadmap_v1.1.md`
- Overrides: `docs/adr/` and the code in `vespera_backend/app/schemas/` when they conflict with Appendix A1’s inlined snippet

## Product

Vespera compiles listening intent into a session contract, plans a rights-eligible queue, plays that queue, and replans unplayed items from reason-coded feedback. It is not a licensed mainstream streaming service in M1.

## In

- Flutter client only; Twilight visual shell frozen
- Two new surfaces: contract-summary + seed picker (one sheet), skip-reason sheet
- One `AudioPlayerService` as playback/handoff source of truth
- 50–100 Jamendo tracks with computed rights decisions
- Anonymous device-bound tokens, minimal events, greedy planner, FTS/tag retrieval, traces
- Public HTTPS demo (VSP-013)

## Out of Milestone 1

- Music DNA screen, + Add Context sheet, microphone, Featured mode overlay, Mood Journey
- iTunes promotional preview as session audio
- Vector DB, embeddings, Essentia/librosa numeric “energy” claims
- Spotify/YouTube as playback sources
- 15–30 person pilot, multilingual benchmark, 300 labeled judgments

## UI freeze

No new main screens. No fabricated catalog, rankings, or “Playing…” toasts before the player reports success.

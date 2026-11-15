# ADR-001: Playback source and capability contract

- Status: Accepted
- Date: 2026-11-15
- Tickets: VSP-003, VSP-004, VSP-006, VSP-008, VSP-012

## Context

The Flutter client currently resolves titles through the iTunes Search API and plays a 30-second promotional preview. The same handoff helpers exist in three services. Milestone 1 must prove a 30-minute session, so preview length cannot fill the session clock, and Apple’s promotional-preview terms are not a session license.

## Decision

1. **Jamendo full-length streams** are the only Milestone 1 in-app session audio, and only after a stored positive `DataRightsRecord`.
2. **Apple iTunes Search** is catalog lookup and external handoff. Promotional previews are `PlaybackMode.PREVIEW` with `playable_ms = 0`, `session_eligible = false`, and `preview_asset_ms` set to the clip length. They never contribute to planner time and are not played as session audio.
3. **Spotify / YouTube Music** are handoff-only when a verified provider mapping exists. No search-URL fallback that pretends the track is on that service.
4. `ProviderTrack.playable_ms` is session-countable audio only. `duration_ms` (when stored on the catalog track) is descriptive and is never summed by the planner.
5. One Flutter `AudioPlayerService` (`ChangeNotifier` singleton) is the only playback and deep-link owner. `music_service.dart` and duplicate `openIn*` methods are deleted, not refactored in parallel.
6. Jamendo streams are not passed through `LockCachingAudioSource` or any other offline cache. API terms restrict offline access and broad caching.
7. Instrumental constraints use Jamendo’s source label and must be described as **labelled instrumental by Jamendo**, not as a Vespera-verified acoustic measurement.

## Capability rules

| Mode | `session_eligible` | `playable_ms` | Required fields |
| --- | --- | --- | --- |
| `full_licensed` | true only with a positive rights record | > 0 if eligible | `audio_url`, `license`, `rights_record_id` |
| `preview` | false | 0 | `preview_asset_ms > 0` |
| `handoff` | false | 0 | `deep_link` |

Unknown or failed rights means no playback.

## Consequences

- The acceptance scenario runs on the seeded Jamendo catalog, not on ~60 iTunes clips.
- Home/Explore must later read the same catalog (VSP-014). Until then those screens are not the M1 demo path.
- Schema validators in `app/schemas/track.py` override the contradictory Appendix A1 snippet in the v1.1 markdown.

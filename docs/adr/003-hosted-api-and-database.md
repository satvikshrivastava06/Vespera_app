# ADR-003: Hosted API and database (selection criteria)

- Status: Accepted criteria; vendor pair chosen at VSP-007 / VSP-013
- Date: 2026-11-15
- Tickets: VSP-007, VSP-013

## Context

Docker Compose is not in the repo. A physical-phone demo needs a public HTTPS API **and** a hosted Postgres. Picking the API host first and the database later is how VSP-013 blows its estimate.

Anonymous `POST /auth/anonymous` and the Twilight/agent route will sit on the public internet. A free Groq tier can be drained. Rate limits belong with the first public deploy, not Gate 9.

## Decision (now)

Choose the **API host and Postgres together** before writing production connection strings. Required properties:

- HTTPS URL suitable for `--dart-define=VESPERA_API_BASE_URL=...`
- Migrations run as a deploy step, not by the first request
- `/health` executes `SELECT 1` against Postgres
- Flutter client timeout ≈ 60s with a “waking up the server” state on the existing loading UI
- Single Uvicorn worker until a process-safe limiter exists
- `--proxy-headers` and a trusted forwarded-IP list if behind the host’s proxy, so IP rate limits are not keyed on the proxy
- In-process limiter on bootstrap (about 5 / hour / IP) and on the agent route (about 20 / minute / user)
- Secrets only in host env; never in Flutter

Free-tier sleep, connection caps, and DB pause/expiry must be read from **current** provider docs at selection time. This ADR does not freeze a vendor.

## Decision (deferred to VSP-013)

Record the chosen pair, cold-start behavior, and backup/restore path in an addendum here.

## Consequences

- Local Postgres via Compose is acceptable for development once VSP-007 lands; it is not the phone-demo database.
- CORS is configured for any web client; the Flutter phone client needs reachability, not CORS.
- Default `http://localhost:8000` is invalid on a physical device. Debug on device uses `adb reverse`, a LAN URL, or the public HTTPS URL. Production stays HTTPS-only; do not enable Android cleartext for release.

# Vespera Backend

FastAPI backend for the Vespera adaptive music intelligence system.
Current build: **VSP-012** (M1 milestone — greedy session planner, intent compiler, DB retrieval, anonymous auth).

---

## Quick start (local dev)

```bash
cd vespera_backend
pip install -r requirements.txt
cp .env.example .env        # then edit .env with your keys
python -m alembic upgrade head
python main.py
```

Backend runs at `http://localhost:8000`.  
Interactive API docs: `http://localhost:8000/docs`

---

## Seed the catalog

Before the Twilight agent can return tracks you must seed the Jamendo catalog.

**Prerequisites:**
1. Register a free Jamendo developer account at https://devportal.jamendo.com
2. Read the API terms at https://devportal.jamendo.com/api_terms_of_use
3. Set `JAMENDO_CLIENT_ID` and `JAMENDO_TERMS_CONFIRMED_ON=YYYY-MM-DD` in `.env`

```bash
JAMENDO_CLIENT_ID=your_id JAMENDO_TERMS_CONFIRMED_ON=2026-11-15 \
  python scripts/seed_jamendo.py
```

Restart the API after seeding so it re-indexes the catalog.

---

## Environment variables

See `.env.example` for all variables and their descriptions.

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | SQLite (dev) or `postgresql+asyncpg://...` (prod) |
| `GROQ_API_KEY` | For LLM intent | Groq API key |
| `GROQ_MODEL` | No | Defaults to `llama-3.1-8b-instant` |
| `JAMENDO_CLIENT_ID` | For catalog seed | Jamendo developer client ID |
| `JAMENDO_TERMS_CONFIRMED_ON` | For catalog seed | Date you read current Jamendo terms |
| `ALLOWED_ORIGINS` | Yes in prod | Comma-separated Flutter app URLs |
| `PORT` | No | Defaults to `8000` |

---

## Deployment (Render free tier)

1. Push the `vespera_backend/` directory to a GitHub repo.
2. Create a new **Web Service** on Render, point to the repo.
3. Set build command: `pip install -r requirements.txt && python -m alembic upgrade head`
4. Set start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add a **PostgreSQL** database; copy the internal `DATABASE_URL` and set it as an env var with the `postgresql+asyncpg://` driver prefix.
6. Add all other env vars from the table above.
7. Deploy. The `/health` endpoint is used as the readiness check.

**Note:** Free-tier instances sleep after ~15 min of inactivity. Cold starts take ~50 s. Use the `RELOAD=false` env var in production.

---

## Connect Flutter

Supply the backend URL at build time:

```bash
# Local dev (default — no flag needed)
flutter run -d chrome

# Against your deployed Render backend
flutter run -d chrome \
  --dart-define=VESPERA_API_BASE_URL=https://vespera-backend.onrender.com/api/v1

# Physical device
flutter run \
  --dart-define=VESPERA_API_BASE_URL=https://vespera-backend.onrender.com/api/v1
```

Add `VESPERA_API_BASE_URL` to your Render environment to surface it in the Flutter `--dart-define`.

---

## Smoke test

Verify a running instance (local or deployed):

```bash
# Local
python scripts/smoke_test.py

# Deployed
python scripts/smoke_test.py https://vespera-backend.onrender.com
```

22 checks covering auth, catalog, Twilight agent, events, sessions, and CORS.

---

## Running tests

```bash
python -m pytest tests/ -v
# 99 tests, all pass
```

Tests use an in-memory SQLite DB — no Postgres needed to run the test suite.

---

## Alembic migrations

```bash
# Apply all pending migrations
python -m alembic upgrade head

# Generate a new migration after model changes
python -m alembic revision --autogenerate -m "description"

# Downgrade one step
python -m alembic downgrade -1
```

---

## API surface (M1)

| Endpoint | Method | Description |
|---|---|---|
| `/health` | GET | Readiness check with catalog stats |
| `/api/v1/auth/anonymous` | POST | Bootstrap device-bound token |
| `/api/v1/events` | POST | Idempotent listening event ingestion |
| `/api/v1/catalog` | GET | List session-eligible catalog tracks |
| `/api/v1/catalog/{id}` | GET | Single catalog track |
| `/api/v1/twilight/agent` | POST | Main intent → retrieval → response |
| `/api/v1/sessions` | POST | Create greedy session plan |
| `/api/v1/sessions/{id}` | GET | Read session state and queue |
| `/api/v1/sessions/{id}/feedback` | POST | Skip reason → replan unplayed queue |
| `/api/v1/traces/{id}` | GET | Read recommendation trace |

Legacy home/explore/search feeds remain at `/api/v1/home_feed`, `/api/v1/explore_feed`, `/api/v1/search`.

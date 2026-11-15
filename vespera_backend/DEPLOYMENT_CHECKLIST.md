# Vespera Backend Deployment Checklist

## M1 Exit Criteria: Deployed Working System

**Status:** In Progress  
**Target:** Render.com (free tier)

## Pre-Deployment Checklist

- [x] Backend code complete (VSP-012)
- [x] Database migrations ready (Alembic)
- [x] Health endpoint implemented (`/health`)
- [x] CORS middleware configured
- [x] Environment variables documented (`.env.example`)
- [x] Deployment config created (`render.yaml`, `Procfile`)
- [x] Requirements.txt up to date
- [ ] Jamendo catalog seed script tested
- [ ] Local smoke tests passed

## Deployment Steps

### 1. Create Render Account & PostgreSQL Database

- [ ] Sign up at https://render.com
- [ ] Create new PostgreSQL database (free tier)
- [ ] Note the Internal Database URL (will be like `postgresql://user:pass@host/db`)

### 2. Create Web Service

- [ ] Click "New +" → "Web Service"
- [ ] Connect GitHub repository
- [ ] Select `vespera_backend` as root directory
- [ ] Configure:
  - **Name:** `vespera-backend`
  - **Runtime:** Python 3
  - **Build Command:** `pip install -r requirements.txt && python -m alembic upgrade head`
  - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`

### 3. Set Environment Variables

In Render dashboard → Environment:

```
DATABASE_URL=postgresql+asyncpg://[from step 1, replace postgresql:// with postgresql+asyncpg://]
GROQ_API_KEY=[your Groq API key]
GROQ_MODEL=llama-3.1-8b-instant
JAMENDO_CLIENT_ID=[your Jamendo client ID]
JAMENDO_TERMS_CONFIRMED_ON=2026-11-15
ALLOWED_ORIGINS=http://localhost:8080,https://[your-frontend-url]
RELOAD=false
```

### 4. Deploy & Verify

- [ ] Click "Create Web Service"
- [ ] Wait for deployment (~3-5 minutes first time)
- [ ] Check deployment logs for errors
- [ ] Test health endpoint: `https://vespera-backend.onrender.com/health`
- [ ] Verify API docs: `https://vespera-backend.onrender.com/docs`

### 5. Seed Production Catalog

From local machine (with production DATABASE_URL):

```bash
DATABASE_URL=postgresql+asyncpg://[production-url] \
JAMENDO_CLIENT_ID=[your-id] \
JAMENDO_TERMS_CONFIRMED_ON=2026-11-15 \
python scripts/seed_jamendo.py
```

Or create a one-off job in Render dashboard.

### 6. Production Smoke Test

```bash
python scripts/smoke_test.py https://vespera-backend.onrender.com
```

Expected: 22 checks pass.

### 7. Connect Flutter App

Update Flutter to use deployed backend:

```bash
flutter run -d chrome \
  --dart-define=VESPERA_API_BASE_URL=https://vespera-backend.onrender.com/api/v1
```

## Post-Deployment Verification

- [ ] Health endpoint returns `{"status": "ok", "db": "ok"}`
- [ ] Catalog has tracks: `"catalog_tracks": > 0`
- [ ] Auth endpoint works: `POST /api/v1/auth/anonymous`
- [ ] Twilight agent responds: `POST /api/v1/twilight/agent`
- [ ] CORS allows Flutter origin
- [ ] Cold start time acceptable (~50s on free tier)

## Known Limitations (Free Tier)

- Instance sleeps after 15 minutes inactivity
- Cold start ~50 seconds
- 750 hours/month (enough for dev/demo)
- PostgreSQL: 1GB storage, 97 connections

## Rollback Plan

If deployment fails:
1. Check Render logs for specific errors
2. Verify all env vars are set correctly
3. Test database connectivity
4. Roll back to previous deploy in Render dashboard
5. Fix issues locally and redeploy

## Success Criteria

✅ **M1 Exit Gate:** A publicly accessible backend URL that:
- Returns healthy status
- Serves API documentation
- Handles auth, catalog, and Twilight requests
- Persists data in PostgreSQL
- Is ready for Flutter integration

---

**Deployment URL:** [To be filled after deployment]  
**Deployed At:** [Timestamp]  
**Deployed By:** Kiro + User

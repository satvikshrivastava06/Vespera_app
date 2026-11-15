# Quick Deployment Commands Reference

## Pre-Deploy: Local Verification

```bash
# Check readiness
cd vespera_backend
python scripts/pre_deploy_check.py

# Run tests (optional)
python -m pytest tests/ -v

# Commit and push
cd ..
git add .
git commit -m "Deploy: M1 ready for production"
git push origin main
```

---

## Render.com Deployment

### 1. Get API Keys

**Groq:** https://console.groq.com (free)  
**Jamendo:** https://devportal.jamendo.com (free)

Save these for step 3.

---

### 2. Create Database (Render Dashboard)

1. New+ → PostgreSQL
2. Name: `vespera-db`
3. Database: `vespera`
4. Plan: **Free**
5. Create Database
6. **Copy Internal Database URL** when ready

---

### 3. Create Web Service (Render Dashboard)

1. New+ → Web Service
2. Connect GitHub: `satvikshrivastava06/Vespera_app`
3. Configure:

```yaml
Name: vespera-backend
Root Directory: vespera_backend
Runtime: Python 3
Build Command: pip install -r requirements.txt && python -m alembic upgrade head
Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
Plan: Free
```

4. **Environment Variables** (click Advanced):

```bash
DATABASE_URL=postgresql+asyncpg://[PASTE DB URL, CHANGE postgresql:// TO postgresql+asyncpg://]
GROQ_API_KEY=[your Groq key]
GROQ_MODEL=llama-3.1-8b-instant
JAMENDO_CLIENT_ID=[your Jamendo ID]
JAMENDO_TERMS_CONFIRMED_ON=2026-11-15
ALLOWED_ORIGINS=http://localhost:8080
RELOAD=false
```

5. Create Web Service
6. Wait 3-5 minutes for first deploy
7. **Copy your deployment URL:** `https://vespera-backend-xxxx.onrender.com`

---

### 4. Seed Catalog (Local Machine)

```bash
cd d:\App\vespera_backend

# Set production DATABASE_URL from Render dashboard
$env:DATABASE_URL = "postgresql+asyncpg://[PRODUCTION URL]"
$env:JAMENDO_CLIENT_ID = "[YOUR ID]"
$env:JAMENDO_TERMS_CONFIRMED_ON = "2026-11-15"

python scripts/seed_jamendo.py
```

---

### 5. Verify Deployment

```bash
# Health check
curl https://vespera-backend-xxxx.onrender.com/health

# Full smoke test
python scripts/smoke_test.py https://vespera-backend-xxxx.onrender.com
```

**Expected:** 22/22 checks pass ✓

---

### 6. Connect Flutter

```bash
cd d:\App

flutter run -d chrome `
  --dart-define=VESPERA_API_BASE_URL=https://vespera-backend-xxxx.onrender.com/api/v1
```

---

## Troubleshooting Commands

### Check Render Logs
Go to Render dashboard → Your Service → Logs

### Test Locally First
```bash
cd vespera_backend
python -m uvicorn main:app --host 127.0.0.1 --port 8000
curl http://localhost:8000/health
python scripts/smoke_test.py
```

### Verify Database Connection
```bash
# From Render dashboard, copy DATABASE_URL
$env:DATABASE_URL = "postgresql+asyncpg://..."
python -c "from app.infrastructure.database import init_db; import asyncio; asyncio.run(init_db())"
```

### Re-run Migrations
```bash
cd vespera_backend
python -m alembic upgrade head
```

### Clear Render Cache
Render dashboard → Settings → Clear Build Cache → Rebuild

---

## Common Issues

### "Database connection failed"
- Verify `postgresql+asyncpg://` prefix (not just `postgresql://`)
- Check internal database URL copied correctly
- Ensure database is running (green status in Render)

### "Build failed"
- Check Render logs for specific error
- Verify requirements.txt is committed
- Ensure alembic.ini and migrations/ exist

### "Health returns 500"
- Check environment variables are all set
- Verify GROQ_MODEL is valid: `llama-3.1-8b-instant`
- Check Render logs for Python traceback

### "Catalog empty after seed"
- Verify JAMENDO_CLIENT_ID is correct
- Check production DATABASE_URL in seed command
- Ensure Jamendo API is accessible (not rate-limited)

---

## Post-Deployment Updates

### Deploy Code Changes
```bash
git add .
git commit -m "Your changes"
git push origin main
# Render auto-deploys from main branch
```

### Update Environment Variables
Render dashboard → Your Service → Environment → Edit

### Restart Service
Render dashboard → Manual Deploy → Deploy Latest Commit

---

## M1 Complete Checklist

```
[ ] Backend deployed to Render
[ ] Health endpoint returns 200
[ ] Catalog seeded (50-100 tracks)
[ ] Smoke test passes (22/22)
[ ] Flutter connected
[ ] End-to-end session tested
[ ] M1 marked COMPLETE ✅
```

---

**Quick Link:** https://dashboard.render.com  
**Repo:** https://github.com/satvikshrivastava06/Vespera_app  
**Docs:** See `DEPLOY_NOW.md` for detailed walkthrough

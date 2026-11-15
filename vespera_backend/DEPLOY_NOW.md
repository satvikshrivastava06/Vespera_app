# 🚀 Deploy Vespera Backend to Render.com (5-minute guide)

## What You Need

1. A GitHub account (you have: `satvikshrivastava06`)
2. A Render account (free): https://render.com
3. A Groq API key (free): https://console.groq.com
4. A Jamendo Developer ID (free): https://devportal.jamendo.com

---

## Step 1: Get Your API Keys (5 min)

### Groq API Key
1. Go to https://console.groq.com
2. Sign up / Log in
3. Go to API Keys section
4. Create new key, copy it
5. **Save it somewhere safe**

### Jamendo Client ID
1. Go to https://devportal.jamendo.com
2. Sign up for developer account
3. Read API terms: https://devportal.jamendo.com/api_terms_of_use
4. Get your Client ID from the dashboard
5. **Save it somewhere safe**

---

## Step 2: Push Code to GitHub (1 min)

Your repo: https://github.com/satvikshrivastava06/Vespera_app

```bash
cd d:\App
git add vespera_backend/
git commit -m "Deploy: VSP-013 production-ready backend"
git push origin main
```

---

## Step 3: Deploy to Render (2 min)

### A. Create PostgreSQL Database

1. Go to https://dashboard.render.com
2. Click **"New +"** → **"PostgreSQL"**
3. Settings:
   - **Name:** `vespera-db`
   - **Database:** `vespera`
   - **Region:** Choose closest to you
   - **Plan:** Free
4. Click **"Create Database"**
5. **Wait 1-2 minutes** for provisioning
6. Once ready, copy the **"Internal Database URL"** (looks like `postgresql://vespera_user:xxxx@dpg-xxxx-a/vespera_xxxx`)

### B. Create Web Service

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub: `satvikshrivastava06/Vespera_app`
3. Settings:
   - **Name:** `vespera-backend`
   - **Root Directory:** `vespera_backend`
   - **Runtime:** Python 3
   - **Build Command:** 
     ```
     pip install -r requirements.txt && python -m alembic upgrade head
     ```
   - **Start Command:**
     ```
     uvicorn main:app --host 0.0.0.0 --port $PORT
     ```
   - **Plan:** Free

4. Click **"Advanced"** → Add Environment Variables:

```
DATABASE_URL = postgresql+asyncpg://[paste from step A, but CHANGE postgresql:// to postgresql+asyncpg://]
GROQ_API_KEY = [your Groq key from Step 1]
GROQ_MODEL = llama-3.1-8b-instant
JAMENDO_CLIENT_ID = [your Jamendo ID from Step 1]
JAMENDO_TERMS_CONFIRMED_ON = 2026-11-15
ALLOWED_ORIGINS = http://localhost:8080
RELOAD = false
```

5. Click **"Create Web Service"**

---

## Step 4: Wait & Verify (2 min)

### Deployment Progress
- First deploy takes ~3-5 minutes
- Watch the logs in Render dashboard
- Look for: `Uvicorn running on http://0.0.0.0:10000`

### Test Your Deployment

Once deployed, Render gives you a URL like:
```
https://vespera-backend-xxxx.onrender.com
```

**Test it:**

```bash
# Health check
curl https://vespera-backend-xxxx.onrender.com/health

# Should return:
# {"status":"ok","db":"ok","catalog_tracks":0,"session_eligible":0,"version":"0.12.0"}
```

**View API docs:**
Open in browser:
```
https://vespera-backend-xxxx.onrender.com/docs
```

---

## Step 5: Seed the Catalog (2 min)

Now populate the database with Jamendo tracks:

```bash
cd d:\App\vespera_backend

# Set your production DATABASE_URL from Render dashboard
$env:DATABASE_URL="postgresql+asyncpg://[your-production-url]"
$env:JAMENDO_CLIENT_ID="[your-jamendo-id]"
$env:JAMENDO_TERMS_CONFIRMED_ON="2026-11-15"

python scripts/seed_jamendo.py
```

**Expected output:**
```
Seeded 50-100 tracks
Indexed tracks for search
Done!
```

---

## Step 6: Verify Complete System (1 min)

```bash
# Run smoke test against production
python scripts/smoke_test.py https://vespera-backend-xxxx.onrender.com
```

**Expected:**
```
✓ 22/22 checks passed
✓ Auth works
✓ Catalog has tracks
✓ Twilight agent responds
✓ Sessions work
✓ CORS configured
```

---

## 🎉 Success! Your Backend is Live

**Your deployment URL:**
```
https://vespera-backend-xxxx.onrender.com
```

**What works:**
- ✅ Health checks
- ✅ API documentation
- ✅ Anonymous authentication
- ✅ Catalog with 50-100 Jamendo tracks
- ✅ Twilight agent (intent compiler)
- ✅ Session planning
- ✅ Event logging
- ✅ PostgreSQL persistence

**What to do next:**
1. Update Flutter app to use this URL
2. Test end-to-end flow from Flutter
3. Mark VSP-013 and M1 as COMPLETE ✅

---

## Troubleshooting

### "Build failed"
- Check Render logs for specific error
- Verify `requirements.txt` is correct
- Ensure `alembic.ini` and migrations exist

### "Database connection failed"
- Verify DATABASE_URL has `postgresql+asyncpg://` prefix
- Check database is provisioned and running
- Confirm internal URL was copied correctly

### "Health returns 500"
- Check Render logs for Python exceptions
- Verify all environment variables are set
- Check database migrations ran: `alembic upgrade head`

### "Catalog empty"
- Run seed script with production DATABASE_URL
- Check Jamendo API key is valid
- Verify JAMENDO_TERMS_CONFIRMED_ON is set

---

## Free Tier Limitations

- **Cold starts:** Instance sleeps after 15 min inactivity, ~50s to wake
- **Hours:** 750 hours/month (enough for development)
- **Database:** 1GB storage, sufficient for M1
- **Performance:** Good for demo, not production scale

---

## Update Flutter to Use Production Backend

```bash
flutter run -d chrome \
  --dart-define=VESPERA_API_BASE_URL=https://vespera-backend-xxxx.onrender.com/api/v1
```

---

**Deployment Date:** [To be filled]  
**M1 Status:** READY FOR EXIT GATE ✅

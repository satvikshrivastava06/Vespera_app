# Production Deployment Guide (M1)

**CRITICAL:** Render's free Postgres expires after 30 days. Use Neon free tier instead.

## Prerequisites

1. **Neon account** (free tier, no expiry): https://neon.tech
2. **Render account** (free tier): https://render.com  
3. **Jamendo API credentials**: https://devportal.jamendo.com
4. **Groq API key**: https://console.groq.com

---

## Step 1: Provision Neon Postgres (Free, No Expiry)

1. Go to https://console.neon.tech
2. Create new project: `vespera-m1`
3. Region: Choose closest to you
4. Plan: **Free Tier** (3GB storage, no expiry)
5. Copy the **connection string** (starts with `postgresql://`)
6. **Important:** Change `postgresql://` to `postgresql+asyncpg://` for SQLAlchemy async

Example:
```
# Neon gives you:
postgresql://user:pass@ep-xxx.region.aws.neon.tech/main

# Change to:
postgresql+asyncpg://user:pass@ep-xxx.region.aws.neon.tech/main
```

**Save this URL** — you'll need it for Render and for seeding.

---

## Step 2: Deploy to Render.com

1. Go to https://dashboard.render.com
2. Click **New +** → **Web Service**
3. Connect GitHub: `satvikshrivastava06/Vespera_app`
4. Configure:
   - **Name:** `vespera-backend`
   - **Root Directory:** `vespera_backend`
   - **Runtime:** Python 3
   - **Build Command:**
     ```
     pip install -r requirements.txt && python -m alembic upgrade head
     ```
   - **Start Command:**
     ```
     uvicorn main:app --host 0.0.0.0 --port $PORT --proxy-headers
     ```
   - **Plan:** **Free** (or **Starter** to avoid cold starts in acceptance test)

5. **Environment Variables** (click "Advanced"):

```
DATABASE_URL = postgresql+asyncpg://[YOUR NEON URL]
GROQ_API_KEY = [your Groq API key]
GROQ_MODEL = llama-3.1-8b-instant
JAMENDO_CLIENT_ID = [your Jamendo client ID]
JAMENDO_TERMS_CONFIRMED_ON = 2026-11-20
ALLOWED_ORIGINS = http://localhost:8080,https://[your-flutter-url]
TRUSTED_PROXY_HOPS = 1
RELOAD = false
```

**IMPORTANT:** Set all `sync: false` keys as **secret environment variables** in Render dashboard, not in `render.yaml`.

6. Click **Create Web Service**
7. Wait 3-5 minutes for first deploy
8. **Copy your deployment URL:** `https://vespera-backend-xxxx.onrender.com`

---

## Step 3: Seed Production Catalog

From your local machine:

```powershell
cd vespera_backend

# Set production DATABASE_URL (the Neon URL with postgresql+asyncpg://)
$env:DATABASE_URL = "postgresql+asyncpg://[YOUR NEON URL]"
$env:JAMENDO_CLIENT_ID = "[your Jamendo client ID]"
$env:JAMENDO_TERMS_CONFIRMED_ON = "2026-11-20"

python scripts/seed_jamendo.py
```

**Expected output:**
```
Wrote 80 session-eligible tracks to data/m1_catalog.json
```

**Verify:**
```powershell
curl https://vespera-backend-xxxx.onrender.com/health
```

Should return:
```json
{
  "status": "ok",
  "db": "ok",
  "catalog_tracks": 80,
  "session_eligible": 80,
  "generated_at": "2026-11-20T...",
  "version": "0.12.0"
}
```

---

## Step 4: Run Smoke Test (BEFORE APK Build)

**This must pass before building the APK.**

```powershell
cd vespera_backend
python scripts/smoke_test.py https://vespera-backend-xxxx.onrender.com
```

**Expected: All checks pass** (~30 checks including):
- Health returns 200 with catalog >= 80 tracks
- Auth round-trip works
- Twilight agent returns tracks
- Stream URLs resolve with HTTP 200/206
- CORS headers present

**If ANY check fails:** Fix it before building the APK. A failed smoke test means your acceptance run will fail.

---

## Step 5: Build Signed Release APK

### 5A: Generate Keystore (First Time Only)

```powershell
cd android/app

keytool -genkey -v `
  -keystore vespera-release.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias vespera

# Follow prompts, set a strong password
# SAVE THE PASSWORD — you'll need it for every release
```

### 5B: Create key.properties

Create `android/key.properties` (NOT in version control):

```properties
storePassword=[your keystore password]
keyPassword=[your key password]
keyAlias=vespera
storeFile=app/vespera-release.jks
```

### 5C: Update .gitignore

Verify these are in `.gitignore`:

```
*.jks
key.properties
```

### 5D: Configure build.gradle

Update `android/app/build.gradle`:

```gradle
// Above android { ... }
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... existing release config ...
        }
    }
}
```

### 5E: Build APK

```powershell
cd d:\App

flutter build apk --release `
  --dart-define=VESPERA_API_BASE_URL=https://vespera-backend-xxxx.onrender.com/api/v1
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

**Verify:** Check the URL is HTTPS (not http://). Android 9+ blocks cleartext HTTP in release builds.

---

## Step 6: 30-Minute Acceptance Run

### Setup
1. Copy `app-release.apk` to your phone
2. Install the APK
3. Open Vespera
4. Start a session: "Calm instrumental music for studying"

### Test Scenario (30 minutes, screen locked)
1. **Start playback** (verify first track plays)
2. **Lock screen** — verify lock-screen controls show artist/title
3. Wait 20 minutes (screen locked)
4. **Unlock** — verify playback continued (check position)
5. **Skip** with reason: "Too energetic"
6. Verify queue updated
7. **Turn off WiFi** mid-track
8. Verify error state shows
9. **Turn on WiFi**
10. Verify playback resumes

### Screen Record
- Use Android screen recorder or ADB: `adb shell screenrecord /sdcard/vespera-m1.mp4`
- Capture: initial state, lock screen, skip with reason, network loss recovery

---

## Known Issues (Free Tier)

### Render Cold Start (15-min inactivity)
**Symptom:** First request after 15 min takes ~60s  
**Mitigation:**
- Acceptance test should use **Starter plan** ($7/month), or
- Add external ping to `/health` every 10 minutes (burns free hours)

**Flutter already handles this:**
- Twilight timeout: 75 seconds (allows cold start)
- Other services: use jittered backoff on 429/503

### Neon Free Tier Limits
- 3GB storage (enough for M1, ~40k tracks)
- 100 hours compute/month (API calls only)
- No branching/time-travel (Starter feature)

---

## Rollback Plan

If deployment fails:

1. **Check Render logs** for specific error
2. **Verify env vars** (especially DATABASE_URL prefix)
3. **Test Neon connection** locally:
   ```powershell
   $env:DATABASE_URL = "postgresql+asyncpg://[neon-url]"
   python -c "from app.infrastructure.database import init_db; import asyncio; asyncio.run(init_db())"
   ```
4. **Rollback in Render:** Dashboard → Deploys → Rollback to previous

---

## Security Checklist

- [  ] Jamendo client ID not in git history: `git grep -n "[your-id]" $(git rev-list --all)`
- [ ] `*.jks` in `.gitignore`
- [ ] `key.properties` in `.gitignore`
- [ ] `DATABASE_URL` is secret env var (not in render.yaml)
- [ ] Production URL uses HTTPS (not http://)

---

## Success Criteria (M1 Complete)

- [ ] Smoke test passes against production URL
- [ ] Catalog has 80+ session-eligible tracks
- [ ] Stream URLs resolve with 200/206
- [ ] Signed APK installs on physical device
- [ ] 30-minute locked-screen test completes
- [ ] Lock-screen controls work
- [ ] Skip with reason triggers replan
- [ ] Network loss shows error state
- [ ] Screen recording captured

**Only after all pass:** M1 is COMPLETE ✅

---

## Troubleshooting

### "Health returns 503"
- Check Neon console — database must be running
- Verify DATABASE_URL has `postgresql+asyncpg://` prefix
- Run migrations: `python -m alembic upgrade head`

### "Catalog empty after seed"
- Check JAMENDO_CLIENT_ID is valid
- Verify JAMENDO_TERMS_CONFIRMED_ON is set
- Check Jamendo quota (20 req/min limit)

### "Stream URL returns 403/404"
- Jamendo URLs expire after ~6 hours
- Re-run seed script to refresh URLs
- This is expected; production needs periodic refresh

### "APK won't install"
- Check signing config in build.gradle
- Verify keystore path is correct
- Ensure key.properties exists

### "Request timeout after 30s"
- Render cold start takes ~60s
- Flutter timeout is 75s (already fixed)
- First request after sleep is slow — this is expected

---

**Deployment Date:** [To be filled]  
**Production URL:** [To be filled]  
**M1 Status:** [To be filled after acceptance test]

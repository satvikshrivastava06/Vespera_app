#!/usr/bin/env python3
"""Pre-deployment readiness check.

Verifies that the backend is ready to deploy before pushing to production.
Run this locally before deploying to Render/Railway/Fly.

Usage:
    python scripts/pre_deploy_check.py

Exit code 0 = ready to deploy
Exit code 1 = issues found, fix before deploying
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

PASS = "✓"
FAIL = "✗"
WARN = "⚠"

checks_passed = 0
checks_failed = 0
checks_warned = 0


def check(label: str, condition: bool, severity: str = "fail") -> None:
    global checks_passed, checks_failed, checks_warned
    
    if condition:
        print(f"  {PASS}  {label}")
        checks_passed += 1
    elif severity == "warn":
        print(f"  {WARN}  {label}")
        checks_warned += 1
    else:
        print(f"  {FAIL}  {label}")
        checks_failed += 1


def main():
    print("🔍 Vespera Backend Pre-Deployment Check\n")
    
    # Change to backend directory
    backend_dir = Path(__file__).parent.parent
    os.chdir(backend_dir)
    
    # 1. Essential files
    print("📁 Essential Files:")
    check("requirements.txt exists", Path("requirements.txt").exists())
    check("main.py exists", Path("main.py").exists())
    check("Procfile exists", Path("Procfile").exists())
    check("render.yaml exists", Path("render.yaml").exists())
    check("alembic.ini exists", Path("alembic.ini").exists())
    check(".env.example exists", Path(".env.example").exists())
    check("README.md exists", Path("README.md").exists())
    print()
    
    # 2. Directory structure
    print("📂 Directory Structure:")
    check("app/ directory exists", Path("app").is_dir())
    check("app/api/ exists", Path("app/api").is_dir())
    check("app/domain/ exists", Path("app/domain").is_dir())
    check("app/infrastructure/ exists", Path("app/infrastructure").is_dir())
    check("alembic/versions/ exists", Path("alembic/versions").is_dir())
    check("scripts/ exists", Path("scripts").is_dir())
    check("tests/ exists", Path("tests").is_dir())
    print()
    
    # 3. Scripts
    print("🔧 Deployment Scripts:")
    check("seed_jamendo.py exists", Path("scripts/seed_jamendo.py").exists())
    check("smoke_test.py exists", Path("scripts/smoke_test.py").exists())
    print()
    
    # 4. Git checks
    print("🔄 Version Control:")
    check(".git directory exists", Path("../.git").is_dir())
    check(".gitignore exists", Path("../.gitignore").exists())
    
    # Check if .env is NOT committed
    gitignore_content = Path("../.gitignore").read_text() if Path("../.gitignore").exists() else ""
    check(".env is gitignored", ".env" in gitignore_content or "*env" in gitignore_content)
    
    # Warn if .env exists locally
    check(".env exists locally", not Path(".env").exists(), severity="warn")
    print()
    
    # 5. Configuration checks
    print("⚙️  Configuration:")
    if Path(".env.example").exists():
        env_example = Path(".env.example").read_text()
        check("DATABASE_URL in .env.example", "DATABASE_URL" in env_example)
        check("GROQ_API_KEY in .env.example", "GROQ_API_KEY" in env_example)
        check("JAMENDO_CLIENT_ID in .env.example", "JAMENDO_CLIENT_ID" in env_example)
        check("ALLOWED_ORIGINS in .env.example", "ALLOWED_ORIGINS" in env_example)
    
    if Path("render.yaml").exists():
        render_yaml = Path("render.yaml").read_text()
        check("render.yaml has buildCommand", "buildCommand" in render_yaml)
        check("render.yaml has startCommand", "startCommand" in render_yaml)
        check("Alembic in buildCommand", "alembic upgrade head" in render_yaml)
    print()
    
    # 6. Code quality checks
    print("🧪 Code Quality:")
    check("No __pycache__ in repo", not Path("__pycache__").exists() or 
          Path("../.gitignore").exists() and "__pycache__" in Path("../.gitignore").read_text())
    check("No .pyc files in repo", not list(Path(".").rglob("*.pyc")))
    check("No .db files in repo root", not Path("vespera.db").exists() or
          Path("../.gitignore").exists() and "*.db" in Path("../.gitignore").read_text())
    print()
    
    # 7. Security checks
    print("🔒 Security:")
    check("No hardcoded secrets in main.py", 
          "your_api_key" not in Path("main.py").read_text().lower() if Path("main.py").exists() else False)
    check("Secrets from env vars", 
          "os.environ" in Path("main.py").read_text() or "getenv" in Path("main.py").read_text() 
          if Path("main.py").exists() else False)
    print()
    
    # 8. Documentation
    print("📚 Documentation:")
    check("README.md has deployment section", 
          "deploy" in Path("README.md").read_text().lower() if Path("README.md").exists() else False)
    check("Deployment guide exists", 
          Path("DEPLOY_NOW.md").exists() or Path("../M1_DEPLOYMENT_GUIDE.md").exists())
    print()
    
    # Summary
    print("=" * 60)
    print(f"\n📊 Summary:")
    print(f"  {PASS}  Passed:  {checks_passed}")
    if checks_warned > 0:
        print(f"  {WARN}  Warnings: {checks_warned}")
    if checks_failed > 0:
        print(f"  {FAIL}  Failed:  {checks_failed}")
    print()
    
    if checks_failed == 0:
        print("✅ READY TO DEPLOY!")
        print("\nNext steps:")
        print("  1. Push code to GitHub: git push origin main")
        print("  2. Follow: vespera_backend/DEPLOY_NOW.md")
        print("  3. Deploy to Render.com")
        return 0
    else:
        print("❌ NOT READY - Fix issues above before deploying")
        return 1


if __name__ == "__main__":
    sys.exit(main())

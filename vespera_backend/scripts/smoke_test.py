#!/usr/bin/env python3
"""VSP-013 deployment smoke test.

Verifies that a running Vespera backend instance is healthy and that
all M1 acceptance-critical endpoints respond correctly.

Usage:
    # Local dev
    python scripts/smoke_test.py

    # Against a deployed HTTPS instance
    python scripts/smoke_test.py https://your-vespera-backend.onrender.com

Exit code 0 = all checks passed.
Exit code 1 = one or more checks failed.
"""

from __future__ import annotations

import json
import sys
import time
import urllib.request
import urllib.error

BASE_URL = sys.argv[1].rstrip("/") if len(sys.argv) > 1 else "http://localhost:8000"

PASS = "✓"
FAIL = "✗"
results: list[tuple[str, bool, str]] = []


def check(label: str, ok: bool, detail: str = "") -> None:
    results.append((label, ok, detail))
    symbol = PASS if ok else FAIL
    print(f"  {symbol}  {label}", f"({detail})" if detail else "")


def get(path: str, headers: dict | None = None, timeout: int = 15) -> tuple[int, dict]:
    url = f"{BASE_URL}{path}"
    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return e.code, {}
    except Exception as e:
        return 0, {"error": str(e)}


def post(path: str, body: dict, headers: dict | None = None, timeout: int = 20) -> tuple[int, dict]:
    url = f"{BASE_URL}{path}"
    data = json.dumps(body).encode()
    h = {"Content-Type": "application/json", **(headers or {})}
    req = urllib.request.Request(url, data=data, headers=h, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except Exception:
            return e.code, {}
    except Exception as e:
        return 0, {"error": str(e)}


def main() -> int:
    print(f"\nVespera smoke test → {BASE_URL}\n")

    # 1. Health check
    status, body = get("/health")
    check("GET /health returns 200", status == 200, f"status={status}")
    check("/health.status == 'ok'", body.get("status") == "ok", body.get("status", "?"))
    check("/health reports version", bool(body.get("version")), body.get("version", "?"))

    # 2. Anonymous auth bootstrap
    status, body = post("/api/v1/auth/anonymous", {})
    check("POST /auth/anonymous returns 201", status == 201, f"status={status}")
    token = body.get("token", "")
    user_id = body.get("user_id", "")
    check("Token returned (non-empty)", bool(token), f"len={len(token)}")
    check("user_id returned (non-empty)", bool(user_id))

    if not token:
        print("\n  Bootstrap failed — skipping remaining authenticated tests.")
        return _report()

    auth_headers = {"X-Device-Token": token}

    # 3. Catalog endpoint
    status, body = get("/api/v1/catalog", auth_headers)
    check("GET /catalog returns 200", status == 200, f"status={status}")
    check("GET /catalog returns list", isinstance(body, list), type(body).__name__)

    # 4. Twilight agent
    status, body = post("/api/v1/twilight/agent",
                        {"text": "calm instrumental music"},
                        auth_headers)
    check("POST /twilight/agent returns 200", status == 200, f"status={status}")
    check("Response has schema_version", body.get("schema_version") == "1.0")
    check("Response has status field", body.get("status") in
          ("ready", "partial", "needs_clarification", "error"))
    check("Response has trace_id", bool(body.get("trace_id")))

    # 5. Event ingestion
    import uuid
    status, body = post("/api/v1/events",
                        {"event_type": "impression",
                         "event_id": str(uuid.uuid4())},
                        auth_headers)
    check("POST /events returns 200", status == 200, f"status={status}")
    check("Event ack accepted=True", body.get("accepted") is True)

    # 6. Session creation
    status, body = post("/api/v1/sessions",
                        {"text": "30 minutes of focus music"},
                        auth_headers)
    check("POST /sessions returns 201", status == 201, f"status={status}")
    session_id = body.get("session_id", "")
    check("session_id returned", bool(session_id))
    check("plan_version == 1", body.get("plan_version") == 1)
    check("total_planned_ms is int", isinstance(body.get("total_planned_ms"), int))

    if session_id:
        # 7. Get session
        status, body = get(f"/api/v1/sessions/{session_id}", auth_headers)
        check("GET /sessions/{id} returns 200", status == 200, f"status={status}")
        check("Session state == active", body.get("state") == "active")

    # 8. CORS preflight (OPTIONS)
    url = f"{BASE_URL}/health"
    req = urllib.request.Request(url, method="OPTIONS",
                                  headers={"Origin": "http://localhost:8080",
                                           "Access-Control-Request-Method": "GET"})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            cors_ok = resp.status in (200, 204)
            acao = resp.headers.get("Access-Control-Allow-Origin", "")
            check("CORS preflight returns 200/204", cors_ok, f"status={resp.status}")
            check("CORS Allow-Origin header present", bool(acao), acao)
    except Exception as e:
        check("CORS preflight", False, str(e))

    return _report()


def _report() -> int:
    passed = sum(1 for _, ok, _ in results if ok)
    failed = sum(1 for _, ok, _ in results if not ok)
    print(f"\n{'─'*50}")
    print(f"  {passed} passed  •  {failed} failed  •  {len(results)} total")
    if failed:
        print("\nFailed checks:")
        for label, ok, detail in results:
            if not ok:
                print(f"  {FAIL}  {label} {detail}")
    print()
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

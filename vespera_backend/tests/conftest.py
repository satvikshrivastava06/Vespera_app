"""Shared test configuration.

Rate limiting is off by default so unrelated tests can call public endpoints
freely. Tests that exercise limiting turn it on with monkeypatch.setenv.
"""

import pytest

from app.infrastructure.rate_limit import reset_rate_limits


@pytest.fixture(autouse=True)
def _rate_limits_off_by_default(monkeypatch):
    monkeypatch.setenv("RATE_LIMIT_ENABLED", "false")
    monkeypatch.delenv("TRUSTED_PROXY_HOPS", raising=False)
    reset_rate_limits()
    yield
    reset_rate_limits()

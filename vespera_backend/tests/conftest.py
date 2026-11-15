"""Shared test configuration.

Disables rate limiting for all tests to prevent 429 errors during rapid test execution.
"""

import os
import pytest

@pytest.fixture(scope="session", autouse=True)
def disable_rate_limiting():
    """Disable rate limiting for all tests."""
    os.environ["RATE_LIMIT_ENABLED"] = "false"
    yield
    os.environ.pop("RATE_LIMIT_ENABLED", None)

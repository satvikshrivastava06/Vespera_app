import httpx

from app.infrastructure.http import get_with_backoff


class FakeResponse:
    def __init__(self, status_code):
        self.status_code = status_code
        self.headers = {}
        self.request = httpx.Request("GET", "https://example.com")

    def json(self):
        return {}


class FakeClient:
    def __init__(self):
        self.codes = [429, 200]

    def get(self, url, params=None, headers=None, timeout=None):
        return FakeResponse(self.codes.pop(0))


def test_backoff_retries_429():
    client = FakeClient()
    response = get_with_backoff(client, "https://example.com", sleep=lambda _: None)
    assert response.status_code == 200

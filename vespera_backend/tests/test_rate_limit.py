import pytest
import pytest_asyncio
from fastapi import HTTPException
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from starlette.requests import Request

import app.infrastructure.models  # noqa: F401  (registers tables)
from app.infrastructure.database import Base, get_db
from app.infrastructure.rate_limit import check_rate_limit, client_ip, reset_rate_limits

_engine = create_async_engine("sqlite+aiosqlite:///:memory:", connect_args={"check_same_thread": False})
_Session = async_sessionmaker(_engine, expire_on_commit=False, autoflush=False)


def _request(peer: str = "10.0.0.1", xff: str | None = None) -> Request:
    headers = [(b"x-forwarded-for", xff.encode())] if xff is not None else []
    return Request(
        {"type": "http", "method": "POST", "path": "/", "headers": headers,
         "client": (peer, 1234), "query_string": b""}
    )


@pytest.fixture(autouse=True)
def _limits_on(monkeypatch):
    monkeypatch.setenv("RATE_LIMIT_ENABLED", "true")
    reset_rate_limits()


@pytest.mark.asyncio
async def test_blocks_after_limit_and_sets_retry_after():
    request = _request()
    for _ in range(3):
        await check_rate_limit(request, "t", 3, 60)
    with pytest.raises(HTTPException) as exc:
        await check_rate_limit(request, "t", 3, 60)
    assert exc.value.status_code == 429
    assert int(exc.value.headers["Retry-After"]) >= 1


@pytest.mark.asyncio
async def test_enabled_flag_is_read_on_every_call(monkeypatch):
    monkeypatch.setenv("RATE_LIMIT_ENABLED", "false")
    request = _request()
    for _ in range(10):
        await check_rate_limit(request, "t", 1, 60)


@pytest.mark.asyncio
async def test_explicit_keys_are_isolated():
    request = _request()
    for _ in range(2):
        await check_rate_limit(request, "agent", 2, 60, key="user-a")
    with pytest.raises(HTTPException):
        await check_rate_limit(request, "agent", 2, 60, key="user-a")
    await check_rate_limit(request, "agent", 2, 60, key="user-b")


def test_forged_leftmost_forwarded_entries_are_ignored(monkeypatch):
    monkeypatch.setenv("TRUSTED_PROXY_HOPS", "1")
    first = client_ip(_request(xff="1.1.1.1, 203.0.113.9"))
    second = client_ip(_request(xff="2.2.2.2, 203.0.113.9"))
    assert first == second == "203.0.113.9"


def test_default_uses_socket_peer_and_ignores_header():
    assert client_ip(_request("10.0.0.1", "1.1.1.1")) == "10.0.0.1"


def test_too_few_forwarded_entries_falls_back_to_peer(monkeypatch):
    monkeypatch.setenv("TRUSTED_PROXY_HOPS", "2")
    assert client_ip(_request("10.0.0.1", "203.0.113.9")) == "10.0.0.1"


def test_invalid_hops_value_falls_back_to_peer(monkeypatch):
    monkeypatch.setenv("TRUSTED_PROXY_HOPS", "abc")
    assert client_ip(_request("10.0.0.1", "203.0.113.9")) == "10.0.0.1"


@pytest_asyncio.fixture
async def client():
    from main import app

    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with _Session() as session:
        async def _override():
            yield session

        app.dependency_overrides[get_db] = _override
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            yield ac
        app.dependency_overrides.clear()
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.mark.asyncio
async def test_bootstrap_endpoint_returns_429_on_sixth_call(client):
    for _ in range(5):
        assert (await client.post("/api/v1/auth/anonymous")).status_code == 201
    response = await client.post("/api/v1/auth/anonymous")
    assert response.status_code == 429
    assert int(response.headers["Retry-After"]) >= 1


@pytest.mark.asyncio
async def test_global_bootstrap_cap_holds_when_ips_rotate(client, monkeypatch):
    monkeypatch.setenv("TRUSTED_PROXY_HOPS", "1")
    for i in range(120):
        response = await client.post(
            "/api/v1/auth/anonymous",
            headers={"X-Forwarded-For": f"9.9.9.9, 198.51.100.{i % 250}, 203.0.113.{i}"},
        )
        assert response.status_code == 201, i
    response = await client.post(
        "/api/v1/auth/anonymous", headers={"X-Forwarded-For": "9.9.9.9, 203.0.113.250"}
    )
    assert response.status_code == 429

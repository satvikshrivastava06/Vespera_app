from datetime import datetime, timezone

import httpx

from app.providers.apple import AppleSearchAdapter
from app.schemas.track import PlaybackMode


class FakeResponse:
    def __init__(self, payload, status_code=200):
        self.status_code = status_code
        self._payload = payload
        self.headers = {}
        self.request = httpx.Request("GET", "https://itunes.apple.com/search")

    def json(self):
        return self._payload

    def raise_for_status(self):
        if self.status_code >= 400:
            raise httpx.HTTPStatusError(
                "error", request=self.request, response=httpx.Response(self.status_code)
            )


class FakeClient:
    def __init__(self, responses):
        self.responses = list(responses)
        self.calls = 0

    def get(self, url, params=None, headers=None, timeout=None):
        self.calls += 1
        return self.responses.pop(0)


def test_apple_lookup_is_handoff_not_preview():
    client = FakeClient(
        [
            FakeResponse(
                {
                    "results": [
                        {
                            "trackId": 99,
                            "trackViewUrl": "https://music.apple.com/us/album/x?i=99",
                            "previewUrl": "https://audio-ssl.itunes.apple.com/preview.m4a",
                        }
                    ]
                }
            )
        ]
    )
    adapter = AppleSearchAdapter(client=client, sleep=lambda _: None)
    track = adapter.lookup_handoff("Focus Study Quiet Room")
    assert track is not None
    assert track.playback_mode is PlaybackMode.HANDOFF
    assert track.playable_ms == 0
    assert track.session_eligible is False
    assert track.deep_link.endswith("i=99")
    again = adapter.lookup_handoff("Focus Study Quiet Room")
    assert again is track
    assert client.calls == 1


def test_apple_retries_on_429():
    client = FakeClient(
        [
            FakeResponse({}, status_code=429),
            FakeResponse(
                {
                    "results": [
                        {
                            "trackId": 1,
                            "trackViewUrl": "https://music.apple.com/us/album/x?i=1",
                        }
                    ]
                }
            ),
        ]
    )
    adapter = AppleSearchAdapter(client=client, sleep=lambda _: None)
    track = adapter.lookup_handoff("hello")
    assert track is not None
    assert client.calls == 2

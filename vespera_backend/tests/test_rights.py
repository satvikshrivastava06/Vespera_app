from datetime import date

import pytest

from app.domain.rights import decide_rights

CONFIRMED = date(2026, 11, 15)
BY_NC_SA = "https://creativecommons.org/licenses/by-nc-sa/3.0/"


def test_terms_gate_blocks_until_confirmed():
    with pytest.raises(RuntimeError, match="JAMENDO_TERMS_CONFIRMED_ON"):
        decide_rights(
            BY_NC_SA,
            "https://example.com/a.mp3",
            180,
            "https://www.jamendo.com/track/1",
        )


def test_allowed_license_is_session_eligible():
    decision = decide_rights(
        BY_NC_SA,
        "https://example.com/a.mp3",
        180,
        "https://www.jamendo.com/track/1",
        terms_confirmed_on=CONFIRMED,
    )
    assert decision.session_eligible is True
    assert decision.license_code == "by-nc-sa"
    assert decision.reasons == ()


def test_nd_license_is_not_eligible():
    decision = decide_rights(
        "https://creativecommons.org/licenses/by-nc-nd/3.0/",
        "https://example.com/a.mp3",
        180,
        "https://www.jamendo.com/track/1",
        terms_confirmed_on=CONFIRMED,
    )
    assert decision.session_eligible is False
    assert "license_not_allowed_in_m1:by-nc-nd" in decision.reasons


def test_missing_stream_and_backlink():
    decision = decide_rights(
        BY_NC_SA,
        None,
        180,
        None,
        terms_confirmed_on=CONFIRMED,
    )
    assert decision.session_eligible is False
    assert "missing_stream_url" in decision.reasons
    assert "missing_attribution_backlink" in decision.reasons

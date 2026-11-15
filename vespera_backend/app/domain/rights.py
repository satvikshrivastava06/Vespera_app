"""Compute Milestone 1 session eligibility from Jamendo-facing fields.

Field names follow Jamendo tracks API includes (license_ccurl, audio, duration,
shareurl). Confirm against current R17 docs before seeding. ND licenses are
excluded: trimming, looping or crossfading would arguably be adaptation.

``JAMENDO_TERMS_CONFIRMED_ON`` is a human gate. Leave it None until current
Jamendo API terms are read and written confirmation is recorded.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date, datetime, timezone

JAMENDO_TERMS_CONFIRMED_ON: date | None = None
POLICY_VERSION = "m1-jamendo-v1"

_CC_RE = re.compile(
    r"creativecommons\.org/(?:licenses|publicdomain)/([a-z0-9\-\.]+)/(\d\.\d)",
    re.I,
)
# ND excluded in M1.
_M1_ALLOWED = {"zero", "by", "by-sa", "by-nc", "by-nc-sa"}


@dataclass(frozen=True)
class RightsDecision:
    session_eligible: bool
    license_code: str | None
    reasons: tuple[str, ...]
    policy_version: str
    decided_at: datetime


def decide_rights(
    license_ccurl: str | None,
    audio_url: str | None,
    duration_s: int | None,
    backlink: str | None,
    *,
    terms_confirmed_on: date | None = None,
) -> RightsDecision:
    confirmed = (
        terms_confirmed_on
        if terms_confirmed_on is not None
        else JAMENDO_TERMS_CONFIRMED_ON
    )
    if confirmed is None:
        raise RuntimeError(
            "Set JAMENDO_TERMS_CONFIRMED_ON after confirming current Jamendo terms"
        )

    reasons: list[str] = []
    code: str | None = None
    match = _CC_RE.search(license_ccurl or "")
    if not match:
        reasons.append("license_missing_or_unparseable")
    else:
        code = match.group(1).lower()
        if code not in _M1_ALLOWED:
            reasons.append(f"license_not_allowed_in_m1:{code}")
    if not audio_url:
        reasons.append("missing_stream_url")
    if not duration_s or duration_s <= 0:
        reasons.append("missing_duration")
    if not backlink:
        reasons.append("missing_attribution_backlink")
    return RightsDecision(
        session_eligible=not reasons,
        license_code=code,
        reasons=tuple(reasons),
        policy_version=POLICY_VERSION,
        decided_at=datetime.now(timezone.utc),
    )

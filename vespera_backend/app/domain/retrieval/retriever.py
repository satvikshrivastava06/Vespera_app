"""B0 keyword retriever — VSP-011.

Implements the B0 baseline from the roadmap:
  "B0 = Jamendo tag/keyword matching (not popularity)."

Algorithm:
  1. Build a deduplicated keyword set from intent (search_keywords +
     preferred_genres).
  2. Query ``catalog_track_index`` for session-eligible tracks.
  3. Apply hard filters:
       a. instrumental_label = 'instrumental' when require_instrumental=True.
       b. Skip any track whose search_text contains an excluded genre token.
  4. Score each candidate by keyword overlap count (B0 baseline).
  5. Sort descending by score; ties broken by playable_ms (longer first).
  6. Return top-N ``CandidateResult`` objects with filter decisions attached.

No LLM scores, no vectors, no popularity signals — pure deterministic
keyword/tag matching as required for the first baseline.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.models import CatalogTrackIndex
from app.schemas.intent import CompiledIntent

log = logging.getLogger(__name__)

POLICY_VERSION = "b0-keyword-v1"


@dataclass
class CandidateResult:
    """A single retrieved-and-scored track candidate."""

    track_id: str
    title: str
    artist: str
    image_url: str | None
    audio_url: str | None
    jamendo_share_url: str | None
    playable_ms: int
    session_eligible: bool
    instrumental_label: str | None
    license: str | None

    # Scoring / filter evidence (persisted in TraceItem)
    keyword_score: int = 0
    matched_keywords: list[str] = field(default_factory=list)
    reason_codes: list[str] = field(default_factory=list)

    # Filter verdicts
    passed_session_eligible: bool = True
    passed_instrumental_filter: bool = True
    passed_genre_exclusion: bool = True
    exclusion_reason: str | None = None


async def retrieve(
    intent: CompiledIntent,
    db: AsyncSession,
    limit: int = 10,
) -> list[CandidateResult]:
    """Return up to ``limit`` scored, filtered candidates from the DB index.

    Hard filters are applied in SQL where possible and in Python otherwise.
    Every candidate — including excluded ones — is returned so the caller
    can persist a complete trace.
    """
    # ── 1. Build keyword set ─────────────────────────────────────────────────
    all_keywords = list(
        dict.fromkeys(
            kw.lower().strip()
            for kw in (intent.search_keywords + intent.preferred_genres)
            if kw and kw.strip()
        )
    )
    excl_tokens = [g.lower().strip() for g in intent.excluded_genres if g]

    # ── 2. Query DB — session-eligible only via SQL ─────────────────────────
    stmt = (
        select(CatalogTrackIndex)
        .where(CatalogTrackIndex.session_eligible == True)  # noqa: E712
    )
    result = await db.execute(stmt)
    rows: list[CatalogTrackIndex] = list(result.scalars().all())

    if not rows:
        log.info("catalog_track_index is empty — run index_catalog() first.")
        return []

    # ── 3. Score + filter in Python ──────────────────────────────────────────
    candidates: list[CandidateResult] = []

    for row in rows:
        haystack = row.search_text  # already lowercased at index time

        # Hard filter: excluded genres
        genre_ok = not any(tok in haystack for tok in excl_tokens)
        excl_reason: str | None = None
        if not genre_ok:
            matched_excl = [tok for tok in excl_tokens if tok in haystack]
            excl_reason = f"excluded_genre:{','.join(matched_excl)}"

        # Hard filter: instrumental label
        instr_ok = True
        if intent.require_instrumental is True:
            label = (row.instrumental_label or "").lower()
            instr_ok = label == "instrumental"
            if not instr_ok:
                excl_reason = excl_reason or "instrumental_label_missing_or_non_instrumental"

        # Score by keyword overlap
        matched = [kw for kw in all_keywords if kw and kw in haystack]
        score = len(matched)

        reason_codes: list[str] = []
        if matched:
            reason_codes.append("intent_keyword_match")
        if intent.require_instrumental and instr_ok:
            reason_codes.append("instrumental_filter")
        if intent.preferred_genres and any(g.lower() in haystack for g in intent.preferred_genres):
            reason_codes.append("genre_preference")

        candidate = CandidateResult(
            track_id=row.track_id,
            title=row.title,
            artist=row.artist,
            image_url=row.image_url,
            audio_url=row.audio_url,
            jamendo_share_url=row.jamendo_share_url,
            playable_ms=row.playable_ms,
            session_eligible=row.session_eligible,
            instrumental_label=row.instrumental_label,
            license=row.license,
            keyword_score=score,
            matched_keywords=matched,
            reason_codes=reason_codes if (genre_ok and instr_ok) else [],
            passed_session_eligible=row.session_eligible,
            passed_instrumental_filter=instr_ok,
            passed_genre_exclusion=genre_ok,
            exclusion_reason=excl_reason,
        )
        candidates.append(candidate)

    # ── 4. Sort: filtered-out last, then descending score, then longer first ─
    passing = [c for c in candidates if c.passed_genre_exclusion and c.passed_instrumental_filter]
    excluded = [c for c in candidates if not (c.passed_genre_exclusion and c.passed_instrumental_filter)]

    passing.sort(key=lambda c: (c.keyword_score, c.playable_ms), reverse=True)

    # Return all candidates for trace persistence; only passing ones are shown
    return passing[:limit] + excluded

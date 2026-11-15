"""VSP-010 golden prompt set — 40 prompts split 28 tuning / 12 holdout.

The 12 holdout prompts (HOLDOUT_SET) are NEVER used during compiler tuning
or rule adjustment.  They are run once per release to measure real-world
accuracy on unseen inputs.

Field definitions match CompiledIntent.  None means "not checked".
critical=True means a failure on this field is a release blocker
(zero failures required on hard-constraint negation and scope
classification per roadmap Gate 4).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class GoldenPrompt:
    id: str
    text: str
    # Expected field values — None = "don't check this field"
    expected_goal_contains: Optional[str] = None          # substring match
    expected_scope: Optional[str] = None
    expected_memory_action: Optional[str] = None
    expected_require_instrumental: Optional[bool] = None
    expected_excluded_genres: Optional[list[str]] = None
    expected_preferred_genres: Optional[list[str]] = None
    expected_energy: Optional[str] = None
    expected_duration_min: Optional[int] = None
    expected_negations_contains: Optional[list[str]] = None  # substrings
    expected_ambiguities_raised: bool = False              # True = must flag ≥1 ambiguity
    critical: bool = False   # True = release blocker if wrong


# ── 28 tuning prompts ────────────────────────────────────────────────────────

TUNING_SET: list[GoldenPrompt] = [
    # T01 — basic genre
    GoldenPrompt(
        id="T01",
        text="Play some jazz music",
        expected_preferred_genres=["jazz"],
        expected_scope="current_session",
    ),
    # T02 — energy + activity
    GoldenPrompt(
        id="T02",
        text="I need high energy workout music",
        expected_energy="high",
        expected_scope="current_session",
    ),
    # T03 — instrumental hard constraint
    GoldenPrompt(
        id="T03",
        text="Instrumental only, no vocals please",
        expected_require_instrumental=True,
        expected_negations_contains=["no vocals"],
        critical=True,
    ),
    # T04 — duration
    GoldenPrompt(
        id="T04",
        text="Build me a 30-minute study playlist",
        expected_duration_min=30,
        expected_energy="low",
    ),
    # T05 — negation: genre
    GoldenPrompt(
        id="T05",
        text="Something relaxing, but no hip hop",
        expected_excluded_genres=["hip hop"],
        expected_energy="low",
        expected_negations_contains=["no hip hop"],
        critical=True,
    ),
    # T06 — session scope explicit
    GoldenPrompt(
        id="T06",
        text="Just for tonight I want calm acoustic music",
        expected_scope="current_session",
        expected_memory_action="session_only",
        expected_energy="low",
        critical=True,
    ),
    # T07 — global scope
    GoldenPrompt(
        id="T07",
        text="Never recommend death metal to me again",
        expected_scope="global_explicit_rule",
        expected_memory_action="confirm_global",
        expected_excluded_genres=["metal"],
        critical=True,
    ),
    # T08 — mixed constraints
    GoldenPrompt(
        id="T08",
        text="Chill lofi beats to study to, 45 minutes",
        expected_duration_min=45,
        expected_energy="low",
        expected_preferred_genres=["lofi"],
    ),
    # T09 — explicit negation of instrumental
    GoldenPrompt(
        id="T09",
        text="I want music with lyrics, no instrumentals",
        expected_require_instrumental=False,
        expected_negations_contains=["no instrumental"],
    ),
    # T10 — hour duration
    GoldenPrompt(
        id="T10",
        text="One hour of classical piano",
        expected_duration_min=60,
        expected_preferred_genres=["classical"],
    ),
    # T11 — context scope
    GoldenPrompt(
        id="T11",
        text="When I'm working I always like jazz, remember that",
        expected_scope="context",
        expected_preferred_genres=["jazz"],
    ),
    # T12 — multi-genre preference
    GoldenPrompt(
        id="T12",
        text="Something between indie folk and ambient",
        expected_preferred_genres=["indie", "folk", "ambient"],
    ),
    # T13 — negation artist (generic)
    GoldenPrompt(
        id="T13",
        text="Good music but nothing experimental",
        expected_negations_contains=["no experimental"],
    ),
    # T14 — energy low with genre
    GoldenPrompt(
        id="T14",
        text="Soft ambient music for meditation",
        expected_energy="low",
        expected_preferred_genres=["ambient"],
    ),
    # T15 — novelty preference
    GoldenPrompt(
        id="T15",
        text="Surprise me with something I've never heard before",
        expected_scope="current_session",
    ),
    # T16 — simple intent
    GoldenPrompt(
        id="T16",
        text="Pop music please",
        expected_preferred_genres=["pop"],
    ),
    # T17 — negation + duration
    GoldenPrompt(
        id="T17",
        text="20 minutes of relaxing music, no rock",
        expected_duration_min=20,
        expected_excluded_genres=["rock"],
        expected_energy="low",
        critical=True,
    ),
    # T18 — explicit session boundary
    GoldenPrompt(
        id="T18",
        text="I'm not in the mood for electronic tonight",
        expected_scope="current_session",
        expected_memory_action="session_only",
        expected_excluded_genres=["electronic"],
        critical=True,
    ),
    # T19 — high energy + genre
    GoldenPrompt(
        id="T19",
        text="Fast electronic dance music to keep me going",
        expected_energy="high",
        expected_preferred_genres=["electronic"],
    ),
    # T20 — instrumental + genre
    GoldenPrompt(
        id="T20",
        text="Instrumental jazz, nothing with singing",
        expected_require_instrumental=True,
        expected_preferred_genres=["jazz"],
        expected_negations_contains=["no vocals"],
        critical=True,
    ),
    # T21 — sleep context
    GoldenPrompt(
        id="T21",
        text="Gentle music to help me fall asleep",
        expected_energy="low",
        expected_scope="current_session",
    ),
    # T22 — running / high energy
    GoldenPrompt(
        id="T22",
        text="I'm going running, give me something intense",
        expected_energy="high",
    ),
    # T23 — negation + preferred combination
    GoldenPrompt(
        id="T23",
        text="Rock music but not metal",
        expected_preferred_genres=["rock"],
        expected_excluded_genres=["metal"],
        expected_negations_contains=["no metal"],
        critical=True,
    ),
    # T24 — duration + instrumental + focus
    GoldenPrompt(
        id="T24",
        text="Two hours of instrumental music for deep work",
        expected_duration_min=120,
        expected_require_instrumental=True,
        expected_energy="low",
        critical=True,
    ),
    # T25 — confidence should be non-zero
    GoldenPrompt(
        id="T25",
        text="Something good",
        expected_scope="current_session",
    ),
    # T26 — explicit lyrics preference (not instrumental)
    GoldenPrompt(
        id="T26",
        text="Songs with meaningful lyrics, singer-songwriter style",
        expected_require_instrumental=False,
    ),
    # T27 — context scope + genre
    GoldenPrompt(
        id="T27",
        text="For my morning routine I like upbeat pop",
        expected_scope="context",
        expected_energy="high",
        expected_preferred_genres=["pop"],
    ),
    # T28 — negation scope: "not now" must NOT become global
    GoldenPrompt(
        id="T28",
        text="Not in the mood for country right now",
        expected_scope="current_session",
        expected_memory_action="session_only",
        expected_excluded_genres=["country"],
        critical=True,
    ),
]


# ── 12 holdout prompts (NEVER tune against these) ────────────────────────────

HOLDOUT_SET: list[GoldenPrompt] = [
    # H01 — negation + scope (critical)
    GoldenPrompt(
        id="H01",
        text="No sad music tonight",
        expected_scope="current_session",
        expected_memory_action="session_only",
        critical=True,
    ),
    # H02 — global explicit rule (critical)
    GoldenPrompt(
        id="H02",
        text="I never want to hear reggae ever again",
        expected_scope="global_explicit_rule",
        expected_memory_action="confirm_global",
        expected_excluded_genres=["reggae"],
        critical=True,
    ),
    # H03 — instrumental hard constraint (critical)
    GoldenPrompt(
        id="H03",
        text="Only instrumental tracks, absolutely no singing",
        expected_require_instrumental=True,
        critical=True,
    ),
    # H04 — negation must not set global (critical)
    GoldenPrompt(
        id="H04",
        text="I'm studying so skip anything with vocals for now",
        expected_scope="current_session",
        expected_memory_action="session_only",
        expected_require_instrumental=True,
        critical=True,
    ),
    # H05 — combined negation + duration
    GoldenPrompt(
        id="H05",
        text="30 minutes of upbeat pop with no country whatsoever",
        expected_duration_min=30,
        expected_excluded_genres=["country"],
        expected_energy="high",
        critical=True,
    ),
    # H06 — context scope (critical)
    GoldenPrompt(
        id="H06",
        text="When I'm at the gym I always want metal",
        expected_scope="context",
        expected_preferred_genres=["metal"],
        critical=True,
    ),
    # H07 — simple preference
    GoldenPrompt(
        id="H07",
        text="Some blues music please",
        expected_preferred_genres=["blues"],
    ),
    # H08 — energy + duration
    GoldenPrompt(
        id="H08",
        text="45 minutes of calm music for reading",
        expected_duration_min=45,
        expected_energy="low",
    ),
    # H09 — negation scope boundary (critical)
    GoldenPrompt(
        id="H09",
        text="Not hip hop today",
        expected_scope="current_session",
        expected_memory_action="session_only",
        expected_excluded_genres=["hip hop"],
        critical=True,
    ),
    # H10 — multi-negation
    GoldenPrompt(
        id="H10",
        text="No electronic and no metal, just something acoustic",
        expected_excluded_genres=["electronic", "metal"],
        expected_preferred_genres=["folk"],
        critical=True,
    ),
    # H11 — hour duration + genre
    GoldenPrompt(
        id="H11",
        text="An hour of classical orchestral music",
        expected_duration_min=60,
        expected_preferred_genres=["classical"],
    ),
    # H12 — implicit instrumental (focus context)
    GoldenPrompt(
        id="H12",
        text="Deep focus session, need music without distractions",
        expected_energy="low",
        expected_scope="current_session",
    ),
]

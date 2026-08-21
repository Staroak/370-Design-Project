# Frontend UI Handoff

The database is UI-ready as of `sql/17_ui_readiness.sql` + `sql/18_ui_seed_fill.sql`.
This document is the contract between the database and the frontend that gets built
on top of it: what data exists, which view backs which screen, and the decisions
already made so the UI phase doesn't have to re-litigate them.

## Build the database

```bash
bash sql/run_ui_setup.sh <mysql-root-password>
```

Rebuilds `design_project_370` from scratch (schema → seed → views → roles → ACID
fixes → null fixes → UI layers) and writes smoke-test evidence to
`sql/ui_setup_output.txt`. Do **not** load `13_bulk_data.sql` into a UI database —
its generated ids overlap the UI seed layer and its placeholder rows
(`Team 0001`, `gp00001#gen`) are stress-test junk, not demo data.

## What the demo data now contains

| State | Tournament | Why it exists |
|---|---|---|
| completed | Creator Cup (8-team Valorant bracket) | full bracket, stats, payouts |
| completed | MTB Winter Clash (4-team bracket) | second champion for Q7 |
| completed | MTB TFT Open (8-player solo lobbies) | points-by-placement format |
| completed | Rocket League 1v1 Showdown | 1v1 best-of-3 format |
| **live** | MTB Summer Skirmish | semis played, final scheduled + TBD |
| **upcoming** | MTB Fall Invitational | registered field, no results yet |

Plus: all 56 players have countries and birth dates (the 46 real Creator Cup IGNs
deliberately keep `real_name = NULL` — they are real people's handles, so the UI
falls back to IGN); all 8 teams have region, founded date, and a linked captain;
creators have display names; solo players have prize payouts (`payee_type='player'`);
one payment and one deliverable are `pending` so queues aren't empty.

## Screens → views

| Screen | Backing view | Role tier |
|---|---|---|
| Tournament list / homepage | `v_public_schedule` (+ `Tournament.status` for live/upcoming badges) | audience |
| Bracket page | **`v_public_bracket`** (new): `round`, `bracket_slot`, competitors, winner; NULL competitors = TBD | audience |
| Standings / leaderboard | `v_public_standings` (now direction-aware via `score_direction`) | audience |
| Team rosters | `v_public_rosters` | audience |
| Player stat leaderboard | `v_public_player_stats` | audience |
| My profile (+salary) | `v_my_profile` | player |
| My match history | `v_my_match_history` | player |
| Org payout ledger | `v_my_team_payouts` | esports_org |
| Match-day run sheet | `v_tournament_ops` | staff |
| Deliverable tracker | `v_deliverable_status` (now shows creator names) | staff |
| Data-quality reports | `v_registration_violations`, `v_match_integrity` | staff |
| P&L dashboard | `v_org_financials` | admin |
| Outstanding payments | `v_outstanding_payments` (now includes player payees) | admin |
| Org member directory | `v_org_membership` | admin |
| Sponsor portal | `v_my_contract_deliverables` | sponsor |
| Creator portal | `v_my_creator_assignments` (now named, per-tournament stream counts) | creator |

Write operations = the four procedures in `sql/07_transactions.sql`:
`sp_register_team`, `sp_record_placement`, `sp_pay_team_prize`, `sp_onboard_org`.

## Bracket rendering rules

- `round` is 1-based from the earliest round; `bracket_slot` is the position within
  the round. Label rounds from the top: `MAX(round)` = Final, `MAX(round)-1` = Semis, etc.
- A match with no participants is TBD (the live tournament's final ships this state).
- Winner = the participant with `placement = 1` (unique per match by constraint).
- For non-bracket formats (TFT lobbies, best-of-N series) `round` is the lobby/game
  number and `bracket_slot` is 1 — render as a list, not a tree.

## Vocabularies (decided, some DB-enforced)

- `Tournament.status`: `upcoming | live | completed | cancelled` (CHECK-enforced).
- `Tournament.score_direction`: `high | low` (ENUM; label the standings column
  "points" vs "strokes/time" accordingly).
- `Payments.payee_type`: `staff | team | player` (ENUM). `Payments.status`:
  `pending | paid` by convention (defaults to `pending`; views treat NULL as unpaid).
- `Deliverables.status`: `pending | fulfilled` by convention.
- `Membership.role`: `admin` is load-bearing (admin views filter on it); others free.

## Auth strategy for the mock (decided)

The `v_my_*` views filter on `SESSION_USER()` — real per-person MySQL accounts.
That works for the class demo accounts but not for a pooled web app connection,
and MySQL has no real row-level security. So:

- **Clickable mock (phase 1):** no real auth. Ship a role-switcher (audience,
  player *aus#MTB*, org *QOR*, staff, admin, sponsor *Red Bull*, creator *revrzd*)
  and filter client-side to imitate what each view would return.
- **Real backend (phase 2):** connect as one app account, put the row filtering in
  the API layer (org/player scoping in `WHERE` clauses), and treat the view
  definitions as the specification of what each role may see.

## Known caveats left open (deliberately)

- The 4 BCNF-violating relations are reported, not normalized (Sprint 5 decision —
  decomposing them cascades into views, queries and triggers; nothing UI-facing needs it).
- `Users.password` is a placeholder literal; real hashing belongs to the phase-2 backend.
- No image/logo columns beyond `Creators.profile_pic`; the mock should generate
  avatars from initials.
- `Match` is a reserved word — any ORM config must quote the table name.

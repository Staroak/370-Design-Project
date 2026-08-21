# CSC370 Design Project: Esports Tournament Database

A database for organizing creator tournaments and esports events: tournaments, sponsorship
contracts, deliverables, finances, and prize payouts, shared by multiple tournament
organizers with each org's data isolated.

## Contents

- [Project Schedule](#project-schedule)
- [Project](#project)
- [Files in This Repo](#files-in-this-repo)
- [Initial Functional requirements list:](#initial-functional-requirements-list)
- [Business Requirements:](#business-requirements)
- **Sprint 0**: [Plan](#plan-for-sprint-0)
- **Sprint 1**: [Plan](#plan-for-sprint-1) · [Status Report](#status-report-for-sprint-1)
  - [Conceptual Design](#conceptual-design): [Entities](#entities) · [Relationships](#relationships-junction-tables-multiplicity)
- **Sprint 2**: [Plan](#plan-for-sprint-2) · [Status Report](#status-report-for-sprint-2)
- **Sprint 3**: [Plan](#plan-for-sprint-3) · [Status](#sprint-3-status) · [View catalogue](#view-catalogue)
- **Sprint 4**: [Plan](#sprint-4-plan) · [Status](#sprint-4-status)
  - [ERD changes](#erd-changes) · [ACID audit](#acid-audit) · [ACID results](#acid-results-measured-mysql-8046) · [Durability](#durability)
- **Sprint 5**: [Plan](#sprint-5-plan) · [Limitations](#limitations) · [Goals](#goals) · [Status](#sprint-5-status)

## Project Schedule

- Sprint No. Working Period Weight Due Date
- Project Kick-off 6 July 2026 - 17 July 2026 0% 17 July 2026 11:59 pm
- Sprint 1 18 July 2026 - 24 July 2026 20% 24 July 2026 11:59 pm
- Sprint 2 25 July 2026 - 31 July 2026 20% 31 July 2026 11:59 pm
- Sprint 3 1 August 2026 - 7 August 2026 20% 7 August 2026 11:59 pm
- Sprint 4 8 August 2026 - 14 August 2026 20% 14 August 2026 11:59 pm
- Sprint 5 15 August 2026 - 21 August 2026 20% 21 August 2026 11:59 pm

## Project

Creating a database that helps organize creator tournaments for online games and esports. Handles and tracks tournaments, tournament details (time and date), sponsorship contracts, deliverables, finances (revenue/expenses), and prize payouts. 

## Files in This Repo

| File | What it is |
|------|------------|
| [ERD.pdf](ERD.pdf) | Conceptual design (Chen notation) |
| [sql/01_create_tables.sql](sql/01_create_tables.sql) | Schema: tables, keys, CHECK constraints, APP/TRIGGER notes |
| [sql/02_insert_data.sql](sql/02_insert_data.sql) | Mock data |
| [sql/03_test_queries.sql](sql/03_test_queries.sql) | Business-requirement queries Q1 to Q13, with [output](sql/query_output.txt) |
| [sql/04_views.sql](sql/04_views.sql) | The 16 role views ([catalogue below](#view-catalogue)) |
| [sql/05_roles_and_grants.sql](sql/05_roles_and_grants.sql) | 8 roles, 11 accounts, grants |
| [sql/06_permission_tests.sql](sql/06_permission_tests.sql) | ALLOW/DENY evidence, with [output](sql/permission_test_output.txt) |
| [sql/run_permission_tests.sh](sql/run_permission_tests.sh) | Rebuilds the DB and replays every test |
| [sql/07_transactions.sql](sql/07_transactions.sql) | The multi-table workload as 4 procedures, written correctly |
| [sql/08_acid_tests.sql](sql/08_acid_tests.sql) | Single-session A/C evidence, with [output](sql/acid_test_output.txt) |
| [sql/09_isolation_tests_a.sql](sql/09_isolation_tests_a.sql) · [_b](sql/09_isolation_tests_b.sql) | Two-session concurrency tests, with [output](sql/isolation_test_output.txt) |
| [sql/10_acid_fixes.sql](sql/10_acid_fixes.sql) | 2 UNIQUE, 6 NOT NULL, 6 `ON DELETE CASCADE`, 19 triggers |
| [sql/run_acid_tests.sh](sql/run_acid_tests.sh) | Replays 07 + 08; `--fixed` also applies 10 ([before](sql/acid_test_output.txt) · [after](sql/acid_test_output_fixed.txt)) |
| [sql/run_isolation_tests.sh](sql/run_isolation_tests.sh) | Drives both sessions of 09 concurrently |
| [sql/run_durability_tests.ps1](sql/run_durability_tests.ps1) | D1/D2/D3 crash tests — needs an elevated PowerShell |
| [sql/11_null_tests.sql](sql/11_null_tests.sql) | Dangling-tuple evidence, with [output](sql/null_test_output.txt) |
| [sql/12_null_fixes.sql](sql/12_null_fixes.sql) | 6 corrected views ([after](sql/null_test_output_fixed.txt)) |
| [sql/13_bulk_data.sql](sql/13_bulk_data.sql) | Generator: grows the DB to 370,910 rows |
| [sql/14_indexes.sql](sql/14_indexes.sql) | I/O predictions committed *before* measurement, plus 3 indexes |
| [sql/16_query_rewrites.sql](sql/16_query_rewrites.sql) | Q7 rewritten to fix what no index could |
| [sql/15_scalability_test.sql](sql/15_scalability_test.sql) | Basketball, tennis and golf loaded with zero DDL |
| `sql/run_null_tests.sh` · `run_index_tests.sh` · `run_scalability_test.sh` · `run_q7_rewrite_test.sh` | The Sprint 5 runners |
| [mock-data/](mock-data/) | Source spreadsheets the mock data came from |

## Initial Functional requirements list:

### What tourney organizers would want to see:

- Add users to organizations / teams with role
- Create tournaments per organization, with games, dates, formatting, status, prize pool
- Registering players/teams per tourney
- Records and track match scores, results, winners
- Allow multiple organizations to use one shared database while keeping each org's data isolated.
- All of the organizations and teams that are participating
- Track past player performances
- Track content creator links, if displaying sponsor ads, clicks
- Track Prize payouts & payment status
- Organizers can assign staff/casters/mods and record their payments
- Record revenue and expenses per organization and per tourney
- Event organizers have the ability to add different components to the database such as prize pool, participating teams, and revenue/expenses
- Be able to create reports of profit, sponsor fulfillment and outstanding payments
- Track sponsorship contracts
- Track Content deliverables
- Roles: Admin, staff, esports organization, players/teams, audience (security hierarchy, most to least)
- Track payment logs of each staff (crew/casters/mods) member / winning teams

### What the players/team/audience would want to see:

- Audience can also access database to check for information regarding the event
- Players and team stats
- Time and date of games and tournaments
- Which players and teams are participating
- Total prize pool
- Game schedules
- Event times and dates


## Business Requirements:

- Track each player's individual stats and past performance history
- Identify which sponsors are worth renewing for future events.
- Know outstanding payments (for talent/crew/staff and winners)
- Know whether sponsors deliverables were fulfilled
- Know if a tourney was profitable

Note* Data will be generated as realistic mock data. Can scrape liquidpedia and existing TO company data (if they let us)

## Plan for Sprint 0:

- Form group and scope out the idea
- Discuss ideas with group members and create functional requirements list


## Plan for Sprint 1

- Implement the ERD's syntax to create an initial layout of our database and to explain how the different components relate - will satisfy Basic conceptual desgin
- Implement the usage of multiplicity to organize and direct relations
- Split information into different attributes, entity sets, relationships, identifiers, etc.
- Be able to identify different functional dependencies, and anomalies
- Identify and develop contraints


## Status Report for Sprint 1

### Conceptual Design

#### Entities

**Organization**
- Attributes: org_id(PK), org_name, contact_email, created_date, region
- FDs:
  - org_id -> org_name, contact_email, created_date, region
- Constraints:
  - org_id unique and not null
  - created_date <= current date


**Users**
- Attributes: user_id(PK), full_name, email, password, phone
- FDs:
  - user_id -> full_name, email, password, phone
  - email -> user_id, full_name, password, phone (email is a second candidate key)
- Constraints:
  - user_id and email unique and not null

**Game**
- Attributes: game_id(PK), title, genre, publisher
- FDs:
  - game_id -> title, genre, publisher
- Constraints:
  - game_id and title unique (publisher is not unique - one publisher makes many games)

**Tournament**
- Attributes: tournament_id(PK), org_id(FK), game_id(FK), name, start_date, end_date, format, status, prize_pool
- FDs:
  - tournament_id -> org_id, game_id, name, start_date, end_date, format, status, prize_pool
- Constraints:
  - org_id references an existing Organization
  - game_id references an existing Game
  - start_date <= end_date
  - prize_pool >= 0

**Teams**
- Attributes: team_id(PK), team_name, region, founded_date, game_id(FK), linked_org
- FDs:
  - team_id -> team_name, region, founded_date, game_id, linked_org
- Constraints:
  - team_name must be unique
  - founded_date < current date
  - linked_org references an existing Organization, or is null

**Players**
- Attributes: player_id(PK), ign, real_name, country, birth_date
- FDs:
  - player_id -> ign, real_name, country, birth_date
- Constraints:
  - ign must be unique
  - birth_date < current date

**Match**
- Attributes: match_id(PK), tournament_id(FK), scheduled_time, team1_id(FK), team2_id(FK), winner_team_id(FK), final_score
- FDs:
  - match_id -> tournament_id, scheduled_time, team1_id, team2_id, winner_team_id, final_score
- Constraints:
  - team1_id != team2_id (a team can't play itself)
  - winner_team_id must equal team1_id or team2_id (exactly one)
  - scheduled_time must fall within the tournament's date range
  - final_score > 0

**Sponsors**
- Attributes: sponsor_id(PK), company_name, contact_name, contact_email
- FDs:
  - sponsor_id -> company_name, contact_name, contact_email
- Constraints:
  - company_name must be unique

**Contracts**
- Attributes: contract_id(PK), org_id(FK), tournament_id(FK), party_type(sponsor/creator), sponsor_id(FK), creator_id(FK), start_date, end_date, total_value
- FDs:
  - contract_id -> org_id, tournament_id, party_type, sponsor_id, creator_id, start_date, end_date, total_value
- Constraints:
  - start_date < end_date
  - total_value > 0
  - party_type = sponsor -> sponsor_id filled, creator_id null
  - party_type = creator -> creator_id filled, sponsor_id null

**Creators**
- Attributes: creator_id(PK), twitchlink, instagram, twitter, profile_pic
- FDs:
  - creator_id -> twitchlink, instagram, twitter, profile_pic
- Constraints:
  - at least one social media link must be filled
  - creator_id unique

**Deliverables**
- Attributes: deliverable_id(PK), contract_id(FK), description, type, due_date, status, click_count
- FDs:
  - deliverable_id -> contract_id, description, type, due_date, status, click_count
- Constraints:
  - click_count >= 0
  - description must be filled

**Transactions**
- Attributes: transaction_id(PK), org_id(FK), tournament_id(FK), type(revenue/expense), category, amount, date
- FDs:
  - transaction_id -> org_id, tournament_id, type, category, amount, date
- Constraints:
  - type is either revenue or expense
  - amount >= 0
  - tournament_id may be null (org-level transactions)

**Payments**
- Attributes: payment_id(PK), payee_type(staff/team), staff_user_id(FK), team_id(FK), tournament_id(FK), amount, status, payment_date
- FDs:
  - payment_id -> payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date
- Constraints:
  - payee_type is either staff or team
  - amount > 0
  - exactly one of staff_user_id / team_id is filled:
    - payee_type = staff -> staff_user_id filled, team_id null
    - payee_type = team -> team_id filled, staff_user_id null

#### Relationships (junction tables: multiplicity)

**Membership** - Users <-> Organization (M:N)
- Attributes: user_id(FK), org_id(FK), role, joined_date, left_date; PK {user_id, org_id}
- Constraints:
  - joined_date not null
  - left_date null or >= joined_date (null = active member)

**Registration** - Team <-> Tournament (M:N)
- Attributes: team_id(FK), tournament_id(FK), registration_date, seed; PK {team_id, tournament_id}
- Constraints:
  - team and tournament must be for the same game

**Roster** - Player <-> Team (M:N)
- Attributes: roster_id(PK), player_id(FK), team_id(FK), join_date, leave_date, salary, jersey_number
- Constraints:
  - no player on two active teams
  - join_date <= leave_date
  - salary >= 0
  - jersey_number unique within the team

**StaffAssignments** - Users <-> Tournament (M:N)
- Attributes: user_id(FK), tournament_id(FK), staff_role, pay_amount; PK {user_id, tournament_id}
- Constraints:
  - pay_amount >= 0
  - user can't be assigned to overlapping tournaments
  - user can only have one assignment per tournament and role
  - user must belong to the organization running the tournament

**PlayerMatchStats** - Player <-> Match (M:N)
- Attributes: player_id(FK), match_id(FK), kills, deaths, assists, score; PK {player_id, match_id}
- Constraints:
  - no player in two matches at once
  - kills, deaths, assists, score >= 0

**CreatorAssignment** - Creator <-> Tournament (M:N)
- Attributes: creator_id(FK), tournament_id(FK), role, rate, status; PK {creator_id, tournament_id}
- Constraints:
  - creator must have an active role

**StaffMatches** - Users <-> Match (M:N)
- Attributes: user_id(FK), match_id(FK), role
- Constraints:
  - user cannot be assigned to matches with overlapping times

**CreatorMatches** - Creator <-> Match (M:N)
- Attributes: creator_id(FK), match_id(FK)
- Constraints:
  - no overlapping match times
  - at least 1 creator per match

## Plan for Sprint 2
- Identify BCNF Decomposition
- Write out some of the basic tables and populate with some mock data. 
- Implement schemas in SQL
- Create scenarios on the usability of our db and write lines of SQL to test how we can pull information
- Briefly review sprint 1 and attempt to identify any components or important details we have missed


## Status Report for sprint 2

Problem we identified:

Didn’t set up the ERD as properly as we thought. 
Needed to add an EsportsOrg entity as well, as this service is something that multiple tourney orgs can use. So from a db standpoint, we should track that as a separate table. 

**EsportsOrg** (a team's parent org, e.g. TSM, Cloud9)
- Attributes: esports_org_id(PK), name, region, founded_date
- FDs:
  - esports_org_id -> name, region, founded_date
- Constraints:
  - name must be unique
  - esports_org_id unique and not null

  
- Implemented live and mock data into our db from previous tourneys to see if our db model would support it

- Implemented schemas

- Identified all BNCF Decompositions 

- Created a variety of test scenarios that test the usability of our database to identify underlying constraints or problems and to fulfil the business requirements.

  

## Plan for Sprint 3
*NOTE*
Constraints marked APP/TRIGGER in the schema (same-game registration, no double-active-roster, date-vs-today, time-overlap rules) cannot be expressed as CHECK constraints because they span multiple tables/rows or use the current date. They would be enforced by triggers or application logic in a later sprint.

- Generalize the results model beyond 2-team matches.
It can't represent solo, points-by-placement events (TFT, battle royale).
Deliverable: replace the fixed team1_id/team2_id/winner_team_id columns with a MatchParticipant relation (match_id, competitor_id, placement, points) that supports any number of competitors per match, and add a competitor concept covering both a team and a solo player.

- Success criteria: the revised schema can store both a Valorant team match and an 8-player TFT lobby, and a query can return final standings for each. Also handle individual games where only one player is playing (Chess, Tetris, Rocket League 1v1).

- Develop user access levels and granting access permissions. 
- Create different view queries with different grant levels.

## Sprint 3 Status

- Problem we identified: 
- Our Sprint 3 schema changes didn't fully run. The registration table had old team_id column, but the PK and FK pointed at competitor_id. 

- Added competitor entity so a competitor can be either a team or a single player. Lets us store solo events. Can now determine team_id and player_id


- Created 16 View tables for roles
- Created 8 roles and 11 accounts, and granted on views instead of base tables. 
- Build row-level security out of views, so two adminds from different orgs can run the same query and get different rows. 

- Wrote run_permission_test.sh which rebuilds the db and applies the views and grants. 


### View catalogue

Definitions in [sql/04_views.sql](sql/04_views.sql), grants in [sql/05_roles_and_grants.sql](sql/05_roles_and_grants.sql), ALLOW/DENY evidence in [sql/06_permission_tests.sql](sql/06_permission_tests.sql).

| #  | View                         | Role        | Exposes                                                | Deliberately hides           | Mechanism        | Source |
|----|------------------------------|-------------|--------------------------------------------------------|------------------------------|------------------|--------|
| 1  | `v_public_schedule`          | audience    | tournament, game, organizer, dates, format, prize_pool | `Organization.contact_email` | column           | -      |
| 2  | `v_public_standings`         | audience    | standings for any format or competitor count           | -                            | -                | Q13    |
| 3  | `v_public_rosters`           | audience    | team_name, ign, jersey_number                          | `Roster.salary`              | column           | -      |
| 4  | `v_public_player_stats`      | audience    | kills/deaths/assists, K/D per game                     | -                            | -                | Q6/Q9  |
| 5  | `v_my_profile`               | player      | own profile **+ salary**                               | everyone else's rows         | row              | -      |
| 6  | `v_my_match_history`         | player      | own per-match stats                                    | others' stats                | row              | -      |
| 7  | `v_my_team_payouts`          | esports_org | own teams' prize payouts                               | other orgs' payouts          | row              | -      |
| 8  | `v_tournament_ops`           | staff       | competitors, casters, mods per match                   | -                            | -                | -      |
| 9  | `v_deliverable_status`       | staff       | description, due_date, status, clicks                  | `Contracts.total_value`      | column           | Q11    |
| 10 | `v_registration_violations`  | staff       | cross-game registrations                               | -                            | integrity report | -      |
| 11 | `v_match_integrity`          | staff       | bad participant counts / dup placements                | -                            | integrity report | -      |
| 12 | `v_org_financials`           | admin       | revenue/expense/profit, own org                        | other orgs' money            | row              | Q1     |
| 13 | `v_outstanding_payments`     | admin       | unpaid staff + teams, own org                          | other orgs' payables         | row              | Q8     |
| 14 | `v_org_membership`           | admin       | full_name, email, role                                 | `Users.password`             | column+row       | Q10    |
| 15 | `v_my_contract_deliverables` | sponsor     | own contract value + fulfilment                        | every other sponsor          | row              | Q11    |
| 16 | `v_my_creator_assignments`   | creator     | own rate, status, streams                              | other creators' rates        | row              | -      |

## Sprint 4 Plan

- Determine if our design / different transactions violate any ACID properties
- Determine any subsets within our ERD as well as strong and weak entity sets
- Making sure our current ERD satisfies all aspects of a good conceptual design. 

- Success Criteria: We would be able to identify and fix all violations in our database design resulting in no ACID properties violated. Have correct subsets implemented as well as having new strong and weak entity sets along with foreign keys and primary keys. Our new ERD would satisfy all aspects of a good conceptual design (correctness, completeness, minimality, expressiveness, readability, self-explanation, extensibility, and normality) with no underlying problems.

## Sprint 4 Status

### ERD changes

Made sure our ERD didn't violate any aspects of a good conceptual design. Edited
the initial ERD to contain the new tables we added in Sprint 3
(`MatchParticipant`, `Competitor`).

| # | Change | Type | Affects | Justification |
|---|---|---|---|---|
| 1 | Delete `team1`/`team2`/`winner` diamonds | Repair | Match–Team | Removed from schema in Sprint 3; cannot represent solo or placement-scored events |
| 2 | Add `Competitor` | Repair | new entity | Added Sprint 3, absent from diagram |
| 3 | Add `EsportsOrg` + `BelongsTo` | Repair | new entity | Added Sprint 2, absent from diagram |
| 4 | Add `MatchParticipant` M:N | Repair | Match–Competitor | Replacement for change 1; carries `placement`, `points` |
| 5 | Delete `Match.final_score` | Minimality | Match | Derived from `placement`/`points` — Batini §6.3 |
| 6 | `Competitor` → 2 subsets | Subset | lines 154–172 | Removes ENUM + 2 nullable FKs + CHECK |
| 7 | `Contracts` → 2 subsets | Subset | lines 204–224 | Removes `party_type` + CHECK |
| 8 | `Payments` → 2 subsets | Subset | lines 253–270 | Removes `payee_type` + CHECK |
| 9 | `Match` → weak entity | Weak entity | Match, Tournament | Identifier {tournament_id, match_no}; no meaning outside its tournament |
| 10 | `Deliverable` → weak entity | Weak entity | Deliverable, Contracts | Identifier {contract_id, deliverable_no} |
| 11 | Add `match_no`, `deliverable_no` | Weak entity | 2 entities | Discriminator is what makes the entity weak |
| 12 | Add 13 identifier ellipses | Correctness | all strong entities | v1 shows no attributes; "forgetting an identifier" is a named error |
| 13 | Add attributes to 9 M:N diamonds | Correctness | 9 relationships | Relationship attributes belong on the diamond |
| 14 | Add multiplicity arrowheads | Correctness | ~15 lines | "Forgetting a min/max specification" is a named error |
| 15 | Rename 3× `For` | Minimality | 3 relationships | Duplicate relationship names — the lecture's own example |
| 16 | Straight lines, parents above children | Readability | whole diagram | Named on the readability slide |
| 17 | Split into 3 module pages | Readability | whole diagram | Decomposition "so that changes are localised" |

Rejected as weak entity sets: `Registration`, `Membership`, `PlayerMatchStats`
and the other junction tables. Their keys are entirely borrowed with no
discriminator of their own, so they are relationships, not weak entities.

Created a new metric that focuses on scalability and flexibility without needing
to change the current schema.

### ACID audit

- Audited all four ACID properties and wrote 42 tests: 29 single-session in
  [08_acid_tests.sql](sql/08_acid_tests.sql), 13 two-session in
  [09_isolation_tests_a.sql](sql/09_isolation_tests_a.sql) / [_b](sql/09_isolation_tests_b.sql).
- **Atomicity**: found operations that write more than one table. Wrapped them
  in 4 stored procedures in [07_transactions.sql](sql/07_transactions.sql).
- **Consistency**: found rules our schema stated in comments but never enforced
  — every `-- APP/TRIGGER` note in `01_create_tables.sql`. Fixed with 2 UNIQUE
  constraints, 6 `NOT NULL`, 6 `ON DELETE CASCADE` and 19 triggers in
  [10_acid_fixes.sql](sql/10_acid_fixes.sql).
- **Isolation**: tested dirty read, lost update, non-repeatable read and write
  skew across two sessions. Fixed with `SELECT ... FOR UPDATE` and unique
  indexes.
- **Durability**: the InnoDB preflight in `08_acid_tests.sql` confirms the
  engine *can* provide durability — a MyISAM table would make every atomicity
  test pass for the wrong reason. It does not *demonstrate* durability. The
  three crash tests are in
  [run_durability_tests.ps1](sql/run_durability_tests.ps1) and need an elevated
  shell to hard-kill mysqld; see [Durability](#durability) below.

### ACID results (measured, MySQL 8.0.46)

Every test runs against the **unmodified** schema. An `INSERT` is an input, not
a schema change: we submit a statement a real organizer could submit and record
whether MySQL stops it. When it does not, the illegal row is the *output* — a
genuine gap, not a manufactured one. Verdicts are computed by `COUNT(*)` on real
rows, never asserted by a literal.

| Run | Command | Result |
|-----|---------|--------|
| Single-session A + C, baseline | `bash run_acid_tests.sh <pw>` | **17 GAP · 12 OK · 0 FAIL** → [acid_test_output.txt](sql/acid_test_output.txt) |
| Same, after `10_acid_fixes.sql` | `bash run_acid_tests.sh <pw> --fixed` | **5 GAP · 24 OK · 0 FAIL** → [acid_test_output_fixed.txt](sql/acid_test_output_fixed.txt) |
| Two-session isolation | `bash run_isolation_tests.sh <pw>` | **8 GAP · 5 OK · 0 FAIL** → [isolation_test_output.txt](sql/isolation_test_output.txt) |

**All 12 consistency gaps closed** (C1–C12). Preflight passed: every table
InnoDB, 19 CHECK constraints declared *and* enforced, zero residue after each
run. Verdicts were identical across two isolation runs, so the schedule is
reproducible.

The five that remain are the ones **no schema change can fix**, and saying so is
the point rather than a shortfall:

| | Why it survives |
|---|---|
| A1, A2 | Atomicity is how the *client groups statements*, not a property of the schema. Fix is to call the procedures in [07_transactions.sql](sql/07_transactions.sql). |
| A5 | `CREATE USER` / `GRANT` are DDL and force an implicit commit. Account provisioning can never be atomic with the data it maps to in MySQL. |
| A6 | A hand-rolled multi-statement cascade is not atomic. `A6-FIX` shows the single-statement `DELETE` *is* — it cascades through five tables, fails on `Payments`, and rolls the whole thing back. |
| C13 | Reconciling `Transactions.category='staff'` against `Payments` is a reporting concern; a trigger on either table fires before the other side exists. |

**Isolation — the strongest finding.** I4a, I4b, I4c and I5 relax **nothing**:
real default `REPEATABLE READ`, unmodified schema, both transactions
individually valid — and the prize pool still ends up **4000.00 paid against a
3000.00 pool**. In the language of CSC370-19 these are schedules that are not
conflict-serialisable. I1 and I3-RC *do* lower the isolation level deliberately,
so they are demonstrations of what the default protects against, not defects;
I3-RR runs the identical schedule at our default and comes back clean
(9500.00 twice), which is the evidence that `REPEATABLE READ` earns its keep.

A3 and A4 sit side by side on purpose: a lock-wait timeout (ERROR 1205) rolled
back **only the failing statement** and the transaction committed anyway, while
a deadlock (ERROR 1213) rolled back the **whole** transaction. Same-looking
failure, opposite scope.

### Durability

**Not yet run.** D1/D2/D3 need mysqld hard-killed mid-run, which requires an
elevated shell. [run_durability_tests.ps1](sql/run_durability_tests.ps1) does
all three in about two minutes:

```powershell
# Right-click PowerShell -> Run as Administrator
cd "c:\CSC370 Project\370-Design-Project\sql"
.\run_durability_tests.ps1 -RootPassword '<root-password>'
```

| # | Test | Expected |
|---|------|----------|
| D1 | commit, hard-kill, restart | row **survives** — redo log replay |
| D2 | same with `innodb_flush_log_at_trx_commit = 0` | row **lost** despite a successful COMMIT |
| D3 | insert without committing, hard-kill | row **absent** — undo log at recovery |

D2 deliberately relaxes a *server setting*, not the schema: it shows durability
is a configuration property rather than something InnoDB gives unconditionally.
The setting is a runtime global and is not persisted, so the restart in the
middle of the test restores the `my.ini` value by itself.

A clean shutdown would flush everything and make all three pass for the wrong
reason, which is why the script uses `Stop-Process -Force`.

## Sprint 5 Plan

### Limitations
- Null safety has not been audited. We wrote our views in Sprint 3, before the material on nulls and outer joins. Some joins in `04_views.sql` are inner joins on nullable columns, so they may be dropping dangling tuples silently.

- We normalised to BCNF but never checked for lost dependencies. Sprint 2 used BCNF (module 07); module 23 later showed BCNF can lose functional dependencies. We have not computed our prime attributes to find out.

- No query has been costed or indexed. Physical design is the last unit of the course, so nothing before now could use it. `01_create_tables.sql`  declares 0 indexes and we have never run EXPLAIN.

### Goals

- Check our joins for dangling tuples
Go through every join in `04_views.sql` and `03_test_queries.sql` and flag the
ones on nullable columns. Write `09_null_tests.sql` to prove each case.
→ MEASURE: X of 16 views dropped rows before, 0 after.

- Check our BCNF work for lost dependencies (3NF)
Find the keys and prime attributes for all 24 relations.
→ MEASURE: report L, the number of FDs our BCNF decomposition lost. Show L = 0,
or give the 3NF decomposition that keeps them.

- Add indexes and measure them
Grow the data past 100k rows first, or MySQL just scans everything. Take the 3
slowest of Q1-Q13 and predict their I/O cost before adding any index.
→ MEASURE: all 3 predictions correct, and EXPLAIN shows half the rows examined
on 2 of 3.

- Focus on Scalability and Flexability
See if our schema can handle new data such as: Basketball/tennis tournamnet. 
Can measure success by validating if our db can process new data without modifiying our pre-existing schema
The less we need to update our schema the more successful it'll be.


## Sprint 5 Status

Three of the four goals met their MEASURE. The fourth missed, and the reason it
missed turned out to be the most useful thing we found this sprint.

| Run | Command | Result |
|-----|---------|--------|
| Null safety, baseline | `bash run_null_tests.sh <pw>` | **11 GAP · 9 OK · 0 FAIL** → [null_test_output.txt](sql/null_test_output.txt) |
| Same, after `12_null_fixes.sql` | `bash run_null_tests.sh <pw> --fixed` | **5 GAP · 16 OK · 0 FAIL** → [null_test_output_fixed.txt](sql/null_test_output_fixed.txt) |
| Scalability | `bash run_scalability_test.sh <pw>` | **11 PASS · 13 GAP · 0 FAIL** → [scalability_test_output.txt](sql/scalability_test_output.txt) |
| Physical design | `bash run_index_tests.sh <pw>` | **2 of 3 predictions held** → [index_test_output.txt](sql/index_test_output.txt) |
| Q7 rewrite | `bash run_q7_rewrite_test.sh <pw>` | **70.75× fewer rows examined** → [q7_rewrite_output.txt](sql/q7_rewrite_output.txt) |
| Durability | `.\run_durability_tests.ps1 -RootPassword <pw>` | **D1 OK · D3 OK · D2 did not reproduce** → [durability_test_output.txt](sql/durability_test_output.txt) |

### Null safety

**MEASURE met: 6 of 16 views dropped rows before, 0 after.**

We wrote every view in Sprint 3, before the material on nulls and outer joins,
and never audited the result. Auditing all 47 inner joins found six views losing
rows or corrupting values, and five of the fifteen queries doing the same.

The worst was `v_org_financials`, which inner-joined `Tournament` even though
Sprint 1 explicitly allows `Transactions.tournament_id` to be NULL for org-level
spending. It hid **12,000.00 of 26,200.00** in expenses from an admin reading
their own profit report. `v_outstanding_payments` and Q8 dropped every debt with
no status recorded, because `NULL <> 'paid'` is UNKNOWN rather than TRUE.

Three control tests guard against over-correcting: one proves
`v_registration_violations` **must** keep its inner join, since a naive outer
rewrite invents 10 false violations.

Q1, Q7, Q8, Q9 and Q11 have since been repaired in `03_test_queries.sql` itself,
so the file no longer ships known-broken queries. The five query GAPs in
`null_test_output_fixed.txt` record the defect as it stood before that repair.

### Lost dependencies (3NF)

**MEASURE met: L = 0.**

Closures, keys and prime attributes were computed for all 24 relations. Every
non-trivial FD is checkable on a single relation without a join, so the Sprint 2
decomposition lost nothing and there is no BCNF-versus-3NF tradeoff to make.

The audit did surface **8 BCNF violations across 4 relations**, six of them one
defect repeated three times: an ENUM discriminator where the ERD already calls
for subsets. We are reporting rather than fixing these, since decomposing four
relations this late would cascade into the views, the queries and the triggers.

Worth recording: **4 of the 19 triggers in `10_acid_fixes.sql` exist only
because `tournament_id → org_id` has a non-superkey antecedent.** Normalising
those two relations would delete all four. Sprint 4's ACID work and this
sprint's normalisation work were chasing the same defect from opposite ends.

### Physical design

**MEASURE partly met: 2 of 3 predictions held, not 3. 2 of 3 queries halved,
but only after Q7 was rewritten.**

Cost was predicted with the external memory model *before* any index existed and
committed to `14_indexes.sql`, so it could not be adjusted afterwards.

| Q | Predicted | Measured |
|---|---|---|
| Q1 | 2.00× | **1.95×**, held |
| Q6 | **predicted not to improve** | **no improvement**, held |
| Q7 | 18.6× | **1.00×**, failed |

Q6's entry is a prediction of failure committed in advance: with no `WHERE`
clause and every join a PK equality, an index changes how wide a block is but
never how many tuples an unrestricted aggregate must see.

**Q7 is where we were wrong.** We assumed the MIN/MAX-by-index optimisation
would collapse the dependent subquery to one descent. `EXPLAIN` confirms the
index is chosen and covering, but that optimisation does not fire inside a
`DEPENDENT SUBQUERY`, so the subquery still walks its whole range once per outer
row. Wall clock did improve, 1,443 ms → 487 ms, because the scan became
index-only, but our metric counts rows handed up by the storage engine, so it
is structurally blind to a covering-index win.

The defect was the *shape* of the query, not the choice of index. Computing the
final of every tournament once, as a grouped derived table, cut rows examined
from **502,451 to 7,102, a 70.75× reduction**, with the index unchanged, and
returns results
identical to the null-safe version. See
[16_query_rewrites.sql](sql/16_query_rewrites.sql).

One stated premise of our own plan was also wrong. We wrote that
`01_create_tables.sql` declares 0 indexes and concluded MySQL would scan
everything. The database in fact carries about **62 indexes**: 24 primary keys,
14 UNIQUEs, and 24 that InnoDB creates silently on foreign-key child columns.

### Scalability

**MEASURE met: three new sports, 268 rows, zero DDL.**

Basketball, tennis (singles and doubles in one draw) and golf (16-player field,
cut to 8) were loaded into the unmodified schema. `S0` fingerprints the schema
before any new row exists and `S26` recomputes it, identical both times at
26 tables / 254 columns / 96 constraints / 19 triggers / 16 views.
`v_public_standings` ranked the golf field in exact stroke order without being
redefined. The Sprint 3 `Competitor` / `MatchParticipant` generalisation is what
earns this.

Of 19 defects found, **10 need only a view change, 1 is a deletion, and none
needs a new table.** Everything that broke is what Sprint 3 did not touch:

- **`MatchParticipant.points` has no declared direction.** Its meaning lives only
  inside `ORDER BY SUM(points) DESC`. Loading golf strokes is the natural move
  and `CHECK (points >= 0)` accepts them, and the leaderboard then comes back
  exactly upside down, crowning last place, with no error and no warning.
- **`Payments` cannot pay a solo competitor**, since `payee_type` is
  `ENUM('staff','team')`. Not a new-sport problem: **4 tournaments and 79,000.00
  of prize money already in our data have no representable payee**, including our
  own Sprint 3 events.

### Durability

The three crash tests deferred from Sprint 4 have now been run in an elevated
shell, with `mysqld` hard-killed via `Stop-Process -Force`.

| # | Test | Expected | Result |
|---|------|----------|--------|
| D1 | commit, hard-kill, restart | row survives | **OK**, redo log replay |
| D2 | same with `innodb_flush_log_at_trx_commit = 0` | row lost | **did not reproduce** |
| D3 | insert without committing, hard-kill | row absent | **OK**, undo log at recovery |

D2 was re-run four times and the row survived every time. At setting 0 the log
still flushes roughly once a second, so the kill never landed inside the
unflushed window on our hardware. We are recording what we observed rather than
what we expected. `D2-RESET` confirms the relaxation was never persisted.

## Future Plans
- Normalize the 4 tables with BCNF violations and delete the triggers that only exist to compensate for them
- Widen payments so a solo competitor can be paid
- Add direction flag so the database knows whether a high or low score wins
- Add a frontend UI



- END OF PROJECT FOR SEMESTER

---

## Post-semester: UI readiness

Everything below was added after the final submission, in preparation for the
frontend UI. The graded files above are unchanged; the new work is layered on top.

| File | What it is |
|------|------------|
| [sql/17_ui_readiness.sql](sql/17_ui_readiness.sql) | Schema layer: bracket structure on `Match` (`round`, `bracket_slot`), `payee_type='player'` so solo competitors can be paid, `Tournament.score_direction` (the golf finding), `Creators.display_name`, `Teams.captain_user_id`, status vocabulary CHECK, extended payment triggers, updated views + new `v_public_bracket` |
| [sql/18_ui_seed_fill.sql](sql/18_ui_seed_fill.sql) | Data layer: bracket positions for all 15 seed matches, player/team profile fills, a **live** and an **upcoming** tournament, solo-player prize payouts, creator names, captain links |
| [sql/run_ui_setup.sh](sql/run_ui_setup.sh) | Rebuilds the UI-ready database end to end and smoke-tests every closed gap → `ui_setup_output.txt` |
| [UI_HANDOFF.md](UI_HANDOFF.md) | The database↔frontend contract: screens → views mapping, bracket rendering rules, vocabularies, auth strategy |
| [ui/](ui/) | **Star Tournaments** — the phase-1 clickable frontend (zero dependencies): every screen from the handoff mapping, role switcher for all 7 tiers, interactive constellation starfield. Run `node ui/serve.mjs` and open http://localhost:5370 |

This closes three of the four Future Plans (solo payouts, score direction, and the
groundwork for the frontend UI). The BCNF normalization stays deliberately open —
nothing UI-facing needs it, and Sprint 5 documented why decomposing those four
relations would cascade into the views, queries and triggers.
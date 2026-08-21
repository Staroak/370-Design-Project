
USE design_project_370;


-- ---------------------------------------------------------------------
-- THE NUMBERS TABLE
--
-- One recursive CTE, materialised once. Everything below cross-joins it.
-- cte_max_recursion_depth defaults to 1000, which is far short of the
-- 4,944 rows the largest direct generation needs.
-- ---------------------------------------------------------------------

SET SESSION cte_max_recursion_depth = 100000;

DROP TABLE IF EXISTS bulk_seq;

CREATE TABLE bulk_seq (
    n  INT  NOT NULL
  , PRIMARY KEY (n)
) ENGINE = InnoDB;

INSERT INTO bulk_seq (n)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 20000
)
SELECT n FROM seq;


-- #####################################################################
-- LEVEL 1 -- INDEPENDENT ENTITIES (no outgoing foreign keys)
--
-- Ids are explicit, not AUTO_INCREMENT, wherever a later formula has to
-- predict them. 02_insert_data.sql already does this for Competitor for
-- exactly the same reason.
-- #####################################################################

-- Game 4..10  (02 seeds 1..3)  ->  10 games, game_id 1..10
INSERT INTO Game (game_id, title, genre, publisher)
SELECT 3 + n
     , CONCAT('Generated Title ', LPAD(n, 3, '0'))
     , ELT(1 + (n MOD 5), 'FPS', 'MOBA', 'Auto Battler', 'Sports', 'Fighting')
     , ELT(1 + (n MOD 4), 'Riot Games', 'Valve', 'Psyonix', 'Blizzard')
FROM bulk_seq
WHERE n <= 7;

-- Organization 2..20  (02 seeds 1)  ->  20 orgs, org_id 1..20
INSERT INTO Organization (org_id, org_name, contact_email, created_date, region)
SELECT 1 + n
     , CONCAT('Org ', LPAD(n, 3, '0'), ' Events')
     , CONCAT('staff@org', LPAD(n, 3, '0'), '.gg')
     , DATE_ADD('2019-01-01', INTERVAL n DAY)
     , ELT(1 + (n MOD 5), 'NA', 'EU', 'APAC', 'SA', 'OCE')
FROM bulk_seq
WHERE n <= 19;

-- EsportsOrg 3..40  (02 seeds 1..2).  db_username stays NULL: MySQL allows
-- many NULLs in a UNIQUE index, so UNIQUE (db_username) is not violated.
INSERT INTO EsportsOrg (esports_org_id, name, region, founded_date, db_username)
SELECT 2 + n
     , CONCAT('EsportsOrg ', LPAD(n, 3, '0'))
     , ELT(1 + (n MOD 5), 'NA', 'EU', 'APAC', 'SA', 'OCE')
     , DATE_ADD('2018-01-01', INTERVAL n * 3 DAY)
     , NULL
FROM bulk_seq
WHERE n <= 38;

-- Sponsors 4..200  (02 seeds 1..3)
INSERT INTO Sponsors (sponsor_id, company_name, contact_name, contact_email, db_username)
SELECT 3 + n
     , CONCAT('Sponsor Co ', LPAD(n, 4, '0'))
     , CONCAT('Contact ', LPAD(n, 4, '0'))
     , CONCAT('brand', LPAD(n, 4, '0'), '@sponsor.example')
     , NULL
FROM bulk_seq
WHERE n <= 197;

-- Creators 4..200  (02 seeds 1..3).  CHECK requires at least one social link.
INSERT INTO Creators (creator_id, twitchlink, instagram, twitter, profile_pic, db_username)
SELECT 3 + n
     , CONCAT('twitch.tv/creator', LPAD(n, 4, '0'))
     , CONCAT('instagram.com/creator', LPAD(n, 4, '0'))
     , NULL
     , NULL
     , NULL
FROM bulk_seq
WHERE n <= 197;

-- Users 13..2000  (02 seeds 1..12).  UNIQUE (email) held by the id suffix.
INSERT INTO Users (user_id, full_name, email, password, phone, db_username)
SELECT 12 + n
     , CONCAT('Staff Member ', LPAD(n, 4, '0'))
     , CONCAT('user', LPAD(n, 4, '0'), '@generated.gg')
     , 'hash'
     , NULL
     , NULL
FROM bulk_seq
WHERE n <= 1988;

-- Players 57..5000  (02 seeds 1..56).  UNIQUE (ign) held by the id suffix;
-- the '#gen' tag guarantees no collision with the real Creator Cup igns.
INSERT INTO Players (player_id, ign, real_name, country, birth_date, db_username)
SELECT 56 + n
     , CONCAT('gp', LPAD(n, 5, '0'), '#gen')
     , CONCAT('Generated Player ', LPAD(n, 5, '0'))
     , ELT(1 + (n MOD 6), 'CA', 'US', 'KR', 'BR', 'DE', 'JP')
     , DATE_ADD('1998-01-01', INTERVAL (n MOD 2500) DAY)
     , NULL
FROM bulk_seq
WHERE n <= 4944;


-- #####################################################################
-- LEVEL 2 -- ENTITIES WITH FOREIGN KEYS
-- #####################################################################

-- Teams 9..1000  (02 seeds 1..8).
--
-- game_id = 1 + (team_id MOD 10) is the load-bearing formula of this file:
-- it is what lets Registration pair a team with a same-game tournament using
-- arithmetic alone, and therefore what makes trigger C1 satisfiable.
INSERT INTO Teams (team_id, team_name, region, founded_date, game_id, esports_org_id)
SELECT 8 + n
     , CONCAT('Team ', LPAD(n, 4, '0'))
     , ELT(1 + (n MOD 5), 'NA', 'EU', 'APAC', 'SA', 'OCE')
     , DATE_ADD('2019-01-01', INTERVAL (n MOD 900) DAY)
     , 1 + ((8 + n) MOD 10)
     , 1 + (n MOD 40)
FROM bulk_seq
WHERE n <= 992;

-- Competitor.  Two disjoint id ranges so that later formulas can produce a
-- competitor_id from a team_id or a player_id without a lookup:
--     team   competitor_id =  1000 + team_id     -> 1009..2000
--     player competitor_id = 10000 + player_id   -> 10057..15000
-- 02_insert_data.sql already occupies 1..18.
-- UNIQUE (team_id) and UNIQUE (player_id) hold: each id appears once.
INSERT INTO Competitor (competitor_id, competitor_type, team_id, player_id)
SELECT 1000 + tm.team_id, 'team', tm.team_id, NULL
FROM Teams tm
WHERE tm.team_id >= 9;

INSERT INTO Competitor (competitor_id, competitor_type, team_id, player_id)
SELECT 10000 + pl.player_id, 'player', NULL, pl.player_id
FROM Players pl
WHERE pl.player_id >= 57;

-- Tournament 5..400  (02 seeds 1..4).
--
--   org_id  = 1 + (tournament_id MOD 20)   -> 1..20
--   game_id = 1 + (tournament_id MOD 10)   -> 1..10
--   window  = [start, start + 2 days], starts 4 days apart
--             -> every generated tournament window is DISJOINT from every
--                other, which is what makes the overlap invariants (C8) and
--                the no-overlapping-tournaments rule hold for free.
--   format  = Single Elimination unless tournament_id MOD 4 = 0
--             -> 297 of 396 are Single Elimination, i.e. selectivity 0.75.
--                That number is used in 14_indexes.sql to reject an index on
--                Tournament(format).
INSERT INTO Tournament (tournament_id, org_id, game_id, name, start_date, end_date, format, status, prize_pool)
SELECT 4 + n
     , 1 + ((4 + n) MOD 20)
     , 1 + ((4 + n) MOD 10)
     , CONCAT('Generated Cup ', LPAD(n, 4, '0'))
     , DATE_ADD('2020-01-01', INTERVAL (n - 1) * 4 DAY)
     , DATE_ADD('2020-01-01', INTERVAL (n - 1) * 4 + 2 DAY)
     , IF((4 + n) MOD 4 = 0, 'Points by Placement', 'Single Elimination')
     , 'completed'
     , 1000.00 + (((4 + n) MOD 50) * 100)
FROM bulk_seq
WHERE n <= 396;


-- #####################################################################
-- LEVEL 3 -- RELATIONSHIPS THAT HANG OFF Tournament
-- #####################################################################

-- Registration: 32 competitors per generated tournament, seeds 1..32.
--
-- Seeds 1..16 are TEAM competitors. The team is chosen as
--     team_id = 10 * j + (tournament_id MOD 10),   j in 1..99
-- so team_id MOD 10 = tournament_id MOD 10, hence
--     Teams.game_id = 1 + (team_id MOD 10)
--                   = 1 + (tournament_id MOD 10)
--                   = Tournament.game_id                        (trigger C1)
-- and j in 1..99 keeps team_id in [10, 999], inside the generated range.
-- The 16 values of j are 16 consecutive residues mod 99, so they are distinct.
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
SELECT 1000 + (10 * (1 + ((t.tournament_id * 16 + k.n) MOD 99)) + (t.tournament_id MOD 10))
     , t.tournament_id
     , DATE_SUB(t.start_date, INTERVAL 7 DAY)
     , k.n
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 16
WHERE t.tournament_id >= 5;

-- Seeds 17..32 are PLAYER competitors. A 'player' competitor carries no game
-- of its own, so C1 exempts it and any player will do. 16 consecutive
-- residues mod 4944 are distinct, so the 16 players in a tournament differ.
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
SELECT 10000 + (57 + ((t.tournament_id * 16 + k.n) MOD 4944))
     , t.tournament_id
     , DATE_SUB(t.start_date, INTERVAL 7 DAY)
     , 16 + k.n
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 16
WHERE t.tournament_id >= 5;

-- Membership: every generated user joins two organisations.
-- The FIRST one is 1 + (user_id MOD 20), which is the org of any tournament
-- whose tournament_id is congruent to the user_id mod 20 -- that is what
-- StaffAssignments below relies on to satisfy trigger C7.
-- The second differs from the first because 7 is not congruent to 0 mod 20,
-- so PRIMARY KEY (user_id, org_id) is not violated.
INSERT INTO Membership (user_id, org_id, role, joined_date, left_date)
SELECT 12 + n
     , 1 + ((12 + n) MOD 20)
     , ELT(1 + (n MOD 4), 'admin', 'caster', 'moderator', 'producer')
     , '2019-06-01'
     , NULL
FROM bulk_seq
WHERE n <= 1988;

INSERT INTO Membership (user_id, org_id, role, joined_date, left_date)
SELECT 12 + n
     , 1 + ((12 + n + 7) MOD 20)
     , 'staff'
     , '2019-06-01'
     , NULL
FROM bulk_seq
WHERE n <= 1988;

-- StaffAssignments: 8 staff per generated tournament.
--     user_id = 20 * j + (tournament_id MOD 20),   j in 1..99
-- so user_id MOD 20 = tournament_id MOD 20, so the user's first Membership
-- row is in exactly the org that runs the tournament, and it is still active
-- (left_date NULL).  That is trigger C7 satisfied by arithmetic.
-- j in 1..99 keeps user_id in [20, 1999], inside the generated range.
INSERT INTO StaffAssignments (user_id, tournament_id, staff_role, pay_amount)
SELECT 20 * (1 + ((t.tournament_id * 8 + k.n) MOD 99)) + (t.tournament_id MOD 20)
     , t.tournament_id
     , ELT(1 + (k.n MOD 4), 'admin', 'caster', 'moderator', 'producer')
     , 100.00 + ((k.n * 61) MOD 800)
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 8
WHERE t.tournament_id >= 5;

-- CreatorAssignment: 4 creators per generated tournament.
INSERT INTO CreatorAssignment (creator_id, tournament_id, role, rate, status)
SELECT 4 + ((t.tournament_id * 4 + k.n) MOD 197)
     , t.tournament_id
     , ELT(1 + (k.n MOD 2), 'streamer', 'host')
     , 100.00 + ((k.n * 71) MOD 900)
     , 'active'
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 4
WHERE t.tournament_id >= 5;

-- Roster: one active roster row per generated player, so no player ever holds
-- two active spots (trigger C5).  jersey_number is unique inside a team
-- because for a fixed team -- fixed (n-1) MOD 992 -- the surviving rows come
-- from different FLOOR((n-1)/992) buckets.
INSERT INTO Roster (player_id, team_id, join_date, leave_date, salary, jersey_number)
SELECT 56 + n
     , 9 + ((n - 1) MOD 992)
     , '2021-01-01'
     , NULL
     , 500.00 + ((n * 13) MOD 3000)
     , 1 + FLOOR((n - 1) / 992)
FROM bulk_seq
WHERE n <= 4944;


-- #####################################################################
-- LEVEL 4 -- MONEY
-- #####################################################################

-- Transactions: 50 per generated tournament, 25 revenue and 25 expense.
-- org_id is taken FROM the Tournament row rather than recomputed, which is
-- trigger C11 satisfied by construction.
--
-- The exact 50/50 split of `type` matters to the Q1 prediction in
-- 14_indexes.sql: it is why adding `type` as the second key column of the
-- covering index halves the entries each dependent subquery reads.
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
SELECT t.org_id
     , t.tournament_id
     , IF(k.n MOD 2 = 1, 'revenue', 'expense')
     , ELT(1 + (k.n MOD 6), 'sponsorship', 'ticket sales', 'merch'
                          , 'prize payout', 'production', 'staff')
     , 100.00 + ((k.n * 37 + t.tournament_id) MOD 5000)
     , DATE_ADD(t.start_date, INTERVAL (k.n MOD 14) DAY)
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 50
WHERE t.tournament_id >= 5;

-- Contracts: 5 per generated tournament -- 4 sponsor, 1 creator.
-- contract_id is explicit so Deliverables can be generated against it.
-- org_id from the Tournament row -> trigger C11.  start_date < end_date and
-- total_value > 0 are both CHECKs in 01_create_tables.sql.
INSERT INTO Contracts (contract_id, org_id, tournament_id, party_type, sponsor_id, creator_id, start_date, end_date, total_value)
SELECT 1000 + (t.tournament_id - 5) * 5 + k.n
     , t.org_id
     , t.tournament_id
     , IF(k.n <= 4, 'sponsor', 'creator')
     , IF(k.n <= 4, 4 + ((t.tournament_id * 4 + k.n) MOD 197), NULL)
     , IF(k.n <= 4, NULL, 4 + (t.tournament_id MOD 197))
     , DATE_SUB(t.start_date, INTERVAL 60 DAY)
     , t.end_date
     , 1000.00 + ((t.tournament_id * 7 + k.n * 131) MOD 20000)
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 5
WHERE t.tournament_id >= 5;

-- Deliverables: 5 per generated contract, 1 in 4 left 'pending'.
INSERT INTO Deliverables (contract_id, description, type, due_date, status, click_count)
SELECT c.contract_id
     , CONCAT('Deliverable ', k.n, ' for contract ', c.contract_id)
     , ELT(1 + (k.n MOD 3), 'branding', 'activation', 'content')
     , c.end_date
     , IF((c.contract_id + k.n) MOD 4 = 0, 'pending', 'fulfilled')
     , (c.contract_id * k.n) MOD 5000
FROM Contracts c
JOIN bulk_seq k ON k.n <= 5
WHERE c.contract_id > 1000;

-- Payments, team half: 16 payouts per generated tournament.
-- The team formula is IDENTICAL to the one Registration used, so every payee
-- is a registered team (trigger C9).  16 * prize_pool/32 = prize_pool/2, so
-- the total never exceeds the pool (trigger C10).
INSERT INTO Payments (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
SELECT 'team'
     , NULL
     , 10 * (1 + ((t.tournament_id * 16 + k.n) MOD 99)) + (t.tournament_id MOD 10)
     , t.tournament_id
     , ROUND(t.prize_pool / 32, 2)
     , IF(k.n MOD 5 = 0, 'pending', 'paid')
     , IF(k.n MOD 5 = 0, NULL, DATE_ADD(t.end_date, INTERVAL 4 DAY))
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 16
WHERE t.tournament_id >= 5;

-- Payments, staff half: 16 per generated tournament, same congruence trick as
-- StaffAssignments so the payee is a real Users row in the running org.
INSERT INTO Payments (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
SELECT 'staff'
     , 20 * (1 + ((t.tournament_id * 16 + k.n) MOD 99)) + (t.tournament_id MOD 20)
     , NULL
     , t.tournament_id
     , 100.00 + ((k.n * 53) MOD 900)
     , IF(k.n MOD 4 = 0, 'pending', 'paid')
     , IF(k.n MOD 4 = 0, NULL, DATE_ADD(t.end_date, INTERVAL 4 DAY))
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 16
WHERE t.tournament_id >= 5;


-- #####################################################################
-- LEVEL 5 -- MATCHES AND THE TWO BIG JUNCTION TABLES
-- #####################################################################

-- Match: 40 per generated tournament, match_id 1001..16840.
--
--     match_id       = 1000 + (tournament_id - 5) * 40 + k
--     scheduled_time = start_date
--                    + FLOOR((k-1)/16) days      -> 0, 1 or 2, inside the
--                                                   3-day window (C6)
--                    + (6 + ((k-1) MOD 16)) hours-> 06:00 .. 21:00
--
-- That expression is STRICTLY INCREASING in k, so MAX(scheduled_time) inside
-- a tournament is attained by exactly one match. Q7 depends on that. Combined
-- with the disjoint tournament windows it also means no two generated matches
-- anywhere in the database share a scheduled_time, which is what makes the
-- three "no overlap at the same instant" triggers (C8) hold for free.
INSERT INTO `Match` (match_id, tournament_id, scheduled_time, final_score)
SELECT 1000 + (t.tournament_id - 5) * 40 + k.n
     , t.tournament_id
     , DATE_ADD(DATE_ADD(t.start_date, INTERVAL FLOOR((k.n - 1) / 16) DAY)
              , INTERVAL 6 + ((k.n - 1) MOD 16) HOUR)
     , CONCAT('13-', k.n MOD 13)
FROM Tournament t
JOIN bulk_seq  k ON k.n <= 40
WHERE t.tournament_id >= 5;

-- MatchParticipant: 4 competitors per generated match, placements 1..4.
--
-- This one is built by JOINING Registration rather than by computing a
-- competitor_id, which is the whole point: a participant that is not
-- registered for the match's tournament cannot be generated, so trigger C2
-- is satisfied structurally rather than by luck.
-- (match_id*4 + 1) .. (match_id*4 + 4) are 4 consecutive residues mod 32, so
-- the 4 seeds picked are distinct and the placements 1..4 are distinct --
-- which is also uq_match_placement from 10_acid_fixes.sql.
-- points = 5 - placement, so 4,3,2,1, all >= 0.
INSERT INTO MatchParticipant (match_id, competitor_id, placement, points)
SELECT m.match_id
     , r.competitor_id
     , k.n
     , 5 - k.n
FROM `Match`       m
JOIN bulk_seq      k ON k.n <= 4
JOIN Registration  r ON r.tournament_id = m.tournament_id
                    AND r.seed = 1 + ((m.match_id * 4 + k.n) MOD 32)
WHERE m.match_id > 1000;

-- PlayerMatchStats: 10 players per generated match -- 158,400 rows, the
-- largest relation in the database and the driving table of Q6 and Q9.
-- 10 consecutive residues mod 4944 are distinct, so PRIMARY KEY
-- (player_id, match_id) is not violated.
-- deaths is 1 + (...) rather than (...) on purpose: Q9 computes
-- SUM(kills)/SUM(deaths) and a zero denominator would make it NULL.
INSERT INTO PlayerMatchStats (player_id, match_id, kills, deaths, assists, score)
SELECT 57 + ((m.match_id * 10 + k.n) MOD 4944)
     , m.match_id
     , (m.match_id + k.n * 7) MOD 30
     , 1 + ((m.match_id + k.n * 11) MOD 25)
     , (m.match_id + k.n * 13) MOD 15
     , 100 + ((m.match_id + k.n * 17) MOD 250)
FROM `Match`  m
JOIN bulk_seq k ON k.n <= 10
WHERE m.match_id > 1000;

-- StaffMatches: a caster and a moderator on every generated match.
INSERT INTO StaffMatches (user_id, match_id, role)
SELECT 13 + ((m.match_id * 2 + k.n) MOD 1988)
     , m.match_id
     , IF(k.n = 1, 'caster', 'moderator')
FROM `Match`  m
JOIN bulk_seq k ON k.n <= 2
WHERE m.match_id > 1000;

-- CreatorMatches: one creator streaming every generated match.
INSERT INTO CreatorMatches (creator_id, match_id)
SELECT 4 + (m.match_id MOD 197)
     , m.match_id
FROM `Match` m
WHERE m.match_id > 1000;


-- ---------------------------------------------------------------------
-- CLEAN UP.  bulk_seq is scaffolding, not schema. Dropping it means the
-- database still has exactly the 24 tables 01_create_tables.sql declares.
-- ---------------------------------------------------------------------
DROP TABLE bulk_seq;


-- ---------------------------------------------------------------------
-- ROW COUNT REPORT
--
-- Read out of the tables, not asserted from a literal -- same discipline
-- 08_acid_tests.sql uses for its verdicts.
-- ---------------------------------------------------------------------
SELECT 'Organization'     AS table_name, COUNT(*) AS rows_now FROM Organization
UNION ALL SELECT 'EsportsOrg',           COUNT(*) FROM EsportsOrg
UNION ALL SELECT 'Game',                 COUNT(*) FROM Game
UNION ALL SELECT 'Users',                COUNT(*) FROM Users
UNION ALL SELECT 'Players',              COUNT(*) FROM Players
UNION ALL SELECT 'Sponsors',             COUNT(*) FROM Sponsors
UNION ALL SELECT 'Creators',             COUNT(*) FROM Creators
UNION ALL SELECT 'Teams',                COUNT(*) FROM Teams
UNION ALL SELECT 'Competitor',           COUNT(*) FROM Competitor
UNION ALL SELECT 'Tournament',           COUNT(*) FROM Tournament
UNION ALL SELECT 'Match',                COUNT(*) FROM `Match`
UNION ALL SELECT 'Contracts',            COUNT(*) FROM Contracts
UNION ALL SELECT 'Deliverables',         COUNT(*) FROM Deliverables
UNION ALL SELECT 'Transactions',         COUNT(*) FROM Transactions
UNION ALL SELECT 'Payments',             COUNT(*) FROM Payments
UNION ALL SELECT 'Membership',           COUNT(*) FROM Membership
UNION ALL SELECT 'Registration',         COUNT(*) FROM Registration
UNION ALL SELECT 'Roster',               COUNT(*) FROM Roster
UNION ALL SELECT 'StaffAssignments',     COUNT(*) FROM StaffAssignments
UNION ALL SELECT 'MatchParticipant',     COUNT(*) FROM MatchParticipant
UNION ALL SELECT 'PlayerMatchStats',     COUNT(*) FROM PlayerMatchStats
UNION ALL SELECT 'CreatorAssignment',    COUNT(*) FROM CreatorAssignment
UNION ALL SELECT 'StaffMatches',         COUNT(*) FROM StaffMatches
UNION ALL SELECT 'CreatorMatches',       COUNT(*) FROM CreatorMatches;

SELECT (SELECT COUNT(*) FROM Organization)     + (SELECT COUNT(*) FROM EsportsOrg)
     + (SELECT COUNT(*) FROM Game)             + (SELECT COUNT(*) FROM Users)
     + (SELECT COUNT(*) FROM Players)          + (SELECT COUNT(*) FROM Sponsors)
     + (SELECT COUNT(*) FROM Creators)         + (SELECT COUNT(*) FROM Teams)
     + (SELECT COUNT(*) FROM Competitor)       + (SELECT COUNT(*) FROM Tournament)
     + (SELECT COUNT(*) FROM `Match`)          + (SELECT COUNT(*) FROM Contracts)
     + (SELECT COUNT(*) FROM Deliverables)     + (SELECT COUNT(*) FROM Transactions)
     + (SELECT COUNT(*) FROM Payments)         + (SELECT COUNT(*) FROM Membership)
     + (SELECT COUNT(*) FROM Registration)     + (SELECT COUNT(*) FROM Roster)
     + (SELECT COUNT(*) FROM StaffAssignments) + (SELECT COUNT(*) FROM MatchParticipant)
     + (SELECT COUNT(*) FROM PlayerMatchStats) + (SELECT COUNT(*) FROM CreatorAssignment)
     + (SELECT COUNT(*) FROM StaffMatches)     + (SELECT COUNT(*) FROM CreatorMatches)
       AS total_rows_all_24_tables;

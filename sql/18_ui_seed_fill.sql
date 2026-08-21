-- =====================================================================
-- 18_ui_seed_fill.sql    UI demo seed backfill and extension
--
-- Run order:  01 -> 02 -> 04 -> (05) -> 10 -> 12 -> 17 -> 18
-- Runs AFTER 17_ui_readiness.sql; 17 owns the schema columns this file fills.
--
-- NOT compatible with 13_bulk_data.sql. That file generates Tournament ids
-- 5..400 and Contract ids that overlap the explicit ids used here. Load 18
-- for the UI dataset OR 13 for the bulk stress dataset, never both on one
-- database.
-- =====================================================================

USE design_project_370;


-- ================== SECTION A: EXISTING ROW BACKFILLS ===============

-- Match bracket positions for the original seeded tournaments.
UPDATE `Match`
SET round = CASE match_id
        WHEN 1  THEN 1
        WHEN 2  THEN 1
        WHEN 3  THEN 1
        WHEN 4  THEN 1
        WHEN 5  THEN 2
        WHEN 6  THEN 2
        WHEN 7  THEN 3
        WHEN 8  THEN 1
        WHEN 9  THEN 1
        WHEN 10 THEN 2
        WHEN 11 THEN 1
        WHEN 12 THEN 2
        WHEN 13 THEN 1
        WHEN 14 THEN 2
        WHEN 15 THEN 3
    END
  , bracket_slot = CASE match_id
        WHEN 1  THEN 1
        WHEN 2  THEN 2
        WHEN 3  THEN 3
        WHEN 4  THEN 4
        WHEN 5  THEN 1
        WHEN 6  THEN 2
        WHEN 7  THEN 1
        WHEN 8  THEN 1
        WHEN 9  THEN 2
        WHEN 10 THEN 1
        WHEN 11 THEN 1
        WHEN 12 THEN 1
        WHEN 13 THEN 1
        WHEN 14 THEN 1
        WHEN 15 THEN 1
    END
WHERE match_id BETWEEN 1 AND 15;

-- Creator display names for UI identity.
UPDATE Creators
SET display_name = CASE creator_id
        WHEN 1 THEN 'revrzd'
        WHEN 2 THEN 'almondfps'
        WHEN 3 THEN 'JareBear'
    END
WHERE creator_id IN (1, 2, 3);

-- Team regions, founding dates and captain links.
UPDATE Teams
SET region = 'NA'
  , founded_date = DATE_ADD('2025-10-01', INTERVAL team_id * 7 DAY)
  , captain_user_id = team_id
WHERE team_id BETWEEN 1 AND 8;

-- real_name stays NULL on purpose (real people's handles; the UI falls back to IGN)
UPDATE Players
SET country = ELT(1 + (player_id MOD 5), 'Canada','USA','USA','Canada','Mexico')
  , birth_date = DATE_ADD('1999-01-01', INTERVAL ((player_id * 53) MOD 2800) DAY)
WHERE player_id BETWEEN 1 AND 46;

-- Fictional solo entrants get complete profile data.
UPDATE Players
SET real_name = CASE player_id
        WHEN 47 THEN 'Mira Vale'
        WHEN 48 THEN 'Daxon Reed'
        WHEN 49 THEN 'Lena Cross'
        WHEN 50 THEN 'Owen Park'
        WHEN 51 THEN 'Nico Hart'
        WHEN 52 THEN 'Sora Finch'
        WHEN 53 THEN 'Maya Stone'
        WHEN 54 THEN 'Felix Moon'
        WHEN 55 THEN 'Kai Winters'
        WHEN 56 THEN 'Emi Brooks'
    END
  , country = CASE player_id
        WHEN 47 THEN 'Canada'
        WHEN 48 THEN 'Germany'
        WHEN 49 THEN 'USA'
        WHEN 50 THEN 'South Korea'
        WHEN 51 THEN 'Brazil'
        WHEN 52 THEN 'Japan'
        WHEN 53 THEN 'Canada'
        WHEN 54 THEN 'USA'
        WHEN 55 THEN 'Germany'
        WHEN 56 THEN 'South Korea'
    END
  , birth_date = CASE player_id
        WHEN 47 THEN '1999-04-12'
        WHEN 48 THEN '2000-11-03'
        WHEN 49 THEN '2001-07-19'
        WHEN 50 THEN '2002-02-26'
        WHEN 51 THEN '2003-09-08'
        WHEN 52 THEN '2004-06-14'
        WHEN 53 THEN '2005-01-30'
        WHEN 54 THEN '2006-10-22'
        WHEN 55 THEN '2000-05-17'
        WHEN 56 THEN '2002-12-05'
    END
WHERE player_id BETWEEN 47 AND 56;

-- Roster dates for visible team history.
UPDATE Roster
SET join_date = '2026-02-20';

-- Delivered sponsor work gets realistic click counts.
UPDATE Deliverables
SET click_count = CASE deliverable_id
        WHEN 1 THEN 1240
        WHEN 2 THEN 860
        WHEN 3 THEN 2100
        WHEN 6 THEN 940
    END
WHERE deliverable_id IN (1, 2, 3, 6);


-- ==================== SECTION B: UI DEMO TOURNAMENTS ================

-- Two near-term Valorant events for the UI dashboard.
INSERT INTO Tournament (
    tournament_id
  , org_id
  , game_id
  , name
  , start_date
  , end_date
  , format
  , status
  , prize_pool
) VALUES
    (5, 1, 1, 'MTB Summer Skirmish',  '2026-08-20', '2026-08-23', 'Single Elimination', 'live',     4000.00)
  , (6, 1, 1, 'MTB Fall Invitational','2026-09-12', '2026-09-13', 'Single Elimination', 'upcoming', 3000.00);

-- Registrations use existing team competitors.
INSERT INTO Registration (
    competitor_id
  , tournament_id
  , registration_date
  , seed
) VALUES
    (1, 5, '2026-08-01', 1)
  , (2, 5, '2026-08-01', 2)
  , (4, 5, '2026-08-01', 3)
  , (7, 5, '2026-08-01', 4)
  , (3, 6, '2026-08-15', 1)
  , (5, 6, '2026-08-15', 2)
  , (6, 6, '2026-08-15', 3)
  , (8, 6, '2026-08-15', 4);

-- UI bracket matches; unplayed rows intentionally have no participants yet.
INSERT INTO `Match` (
    match_id
  , tournament_id
  , round
  , bracket_slot
  , scheduled_time
  , final_score
) VALUES
    (16, 5, 1, 1, '2026-08-20 18:00:00', '13-9')    -- SF1, played
  , (17, 5, 1, 2, '2026-08-21 18:00:00', '13-11')   -- SF2, played
  , (18, 5, 2, 1, '2026-08-23 18:00:00', NULL)      -- final, not yet played
  , (19, 6, 1, 1, '2026-09-12 15:00:00', NULL)      -- SF1, upcoming
  , (20, 6, 1, 2, '2026-09-12 18:00:00', NULL)      -- SF2, upcoming
  , (21, 6, 2, 1, '2026-09-13 17:00:00', NULL);     -- final, upcoming

-- Played matches only; TBD matches have no participants yet.
INSERT INTO MatchParticipant (
    match_id
  , competitor_id
  , placement
  , points
) VALUES
    (16, 1, 1, 1)
  , (16, 7, 2, 0)
  , (17, 4, 1, 1)
  , (17, 2, 2, 0);

-- Player stats for the two completed Summer Skirmish semifinals.
INSERT INTO PlayerMatchStats (
    player_id
  , match_id
  , kills
  , deaths
  , assists
  , score
) VALUES
    (1,  16, 24, 12, 9, 318)
  , (2,  16, 19, 14, 7, 286)
  , (3,  16, 27, 10, 5, 341)
  , (4,  16, 16, 13, 12, 264)
  , (5,  16, 21, 11, 8, 302)
  , (35, 16, 18, 15, 6, 247)
  , (36, 16, 14, 19, 10, 223)
  , (37, 16, 22, 16, 4, 276)
  , (38, 16, 11, 17, 9, 201)
  , (39, 16, 17, 18, 7, 239)
  , (17, 17, 23, 11, 8, 316)
  , (18, 17, 18, 13, 11, 285)
  , (19, 17, 26, 9, 6, 348)
  , (20, 17, 15, 16, 12, 259)
  , (21, 17, 20, 12, 7, 299)
  , (6,  17, 16, 18, 5, 231)
  , (7,  17, 21, 14, 8, 271)
  , (8,  17, 12, 19, 10, 205)
  , (9,  17, 19, 15, 4, 253)
  , (10, 17, 13, 17, 9, 218);

-- Staff coverage for the UI events.
INSERT INTO StaffAssignments (
    user_id
  , tournament_id
  , staff_role
  , pay_amount
) VALUES
    (9,  5, 'admin',     0.00)
  , (10, 5, 'caster',    450.00)
  , (11, 5, 'moderator', 250.00)
  , (10, 6, 'caster',    450.00);

INSERT INTO StaffMatches (
    user_id
  , match_id
  , role
) VALUES
    (10, 16, 'caster')
  , (10, 17, 'caster')
  , (11, 16, 'moderator');

-- Creator coverage for Summer Skirmish.
INSERT INTO CreatorAssignment (
    creator_id
  , tournament_id
  , role
  , rate
  , status
) VALUES
    (1, 5, 'streamer', 450.00, 'active');

INSERT INTO CreatorMatches (
    creator_id
  , match_id
) VALUES
    (1, 16)
  , (1, 17);

-- Discord sponsor package for Summer Skirmish.
INSERT INTO Contracts (
    contract_id
  , org_id
  , tournament_id
  , party_type
  , sponsor_id
  , creator_id
  , start_date
  , end_date
  , total_value
) VALUES
    (5, 1, 5, 'sponsor', 3, NULL, '2026-07-01', '2026-08-23', 3000.00);

INSERT INTO Deliverables (
    contract_id
  , description
  , type
  , due_date
  , status
  , click_count
) VALUES
    (5, 'Sponsored stream overlay', 'branding',   '2026-08-23', 'fulfilled', 1580)
  , (5, 'Community Discord event',  'activation', '2026-08-22', 'pending',   0);

-- Financial activity for the new UI events.
INSERT INTO Transactions (
    org_id
  , tournament_id
  , type
  , category
  , amount
  , date
) VALUES
    (1, 5, 'revenue', 'sponsorship', 3000.00, '2026-08-01')
  , (1, 5, 'revenue', 'ticket sales', 600.00, '2026-08-20')
  , (1, 5, 'expense', 'production', 1200.00, '2026-08-20')
  , (1, 6, 'revenue', 'sponsorship', 1500.00, '2026-08-18');

-- Solo payouts and one outstanding staff payment.
INSERT INTO Payments (
    payee_type
  , staff_user_id
  , team_id
  , player_id
  , tournament_id
  , amount
  , status
  , payment_date
) VALUES
    ('player', NULL, NULL, 47, 3, 1200.00, 'paid',    '2026-05-05')  -- Setsuko, TFT champion
  , ('player', NULL, NULL, 49, 3,  800.00, 'pending', NULL)          -- Rerolla, runner-up
  , ('player', NULL, NULL, 55, 4, 1000.00, 'paid',    '2026-05-11')  -- Jstn1v1, RL champion
  , ('staff',  10,   NULL, NULL, 5,  450.00, 'pending', NULL);


-- ============================== VERIFY ==============================
SELECT 'ui seed fill applied' AS status
     , (SELECT COUNT(*) FROM Tournament)                                      AS tournaments                       -- expect 6
     , (SELECT COUNT(*) FROM `Match`)                                         AS matches                           -- expect 21
     , (SELECT COUNT(*) FROM `Match` WHERE round IS NOT NULL)                 AS positioned_matches                -- expect 21
     , (SELECT COUNT(*) FROM Players WHERE country IS NOT NULL)               AS players_with_country              -- expect 56
     , (SELECT COUNT(*) FROM Teams WHERE captain_user_id IS NOT NULL)         AS teams_with_captain                -- expect 8
     , (SELECT COUNT(*) FROM Creators WHERE display_name IS NOT NULL)         AS creators_with_display_name        -- expect 3
     , (SELECT COUNT(*) FROM Payments)                                        AS payments;                         -- expect 11

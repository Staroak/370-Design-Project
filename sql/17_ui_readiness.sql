-- =====================================================================
-- 17_ui_readiness.sql    post-semester: schema gaps a frontend UI needs
--
-- Run order:  01 -> 02 -> 04 -> (05) -> 10 -> 12 -> 17 -> 18
-- This file assumes 10_acid_fixes.sql has run: it REPLACES the two
-- trg_payments_valid_* triggers so they understand solo-player payouts.
-- Every change is additive; nothing here breaks 03/06/08/09/11/13/15.
--
-- What it closes, and where the gap was found:
--   1. Match has no bracket structure   -> round + bracket_slot columns
--      (QF/SF/final lived only in comments in 02_insert_data.sql; Q7 had
--       to infer "the final" from MAX(scheduled_time)).
--   2. Payments cannot pay a solo competitor -> payee_type gains 'player'
--      (the Sprint 5 scalability report: 4 tournaments and 79,000.00 of
--       prize money had no representable payee).
--   3. points has no declared direction -> Tournament.score_direction
--      (the golf finding: loading strokes crowned last place).
--   4. Creators have no name            -> display_name column
--      (views rendered 'creator #3' or a raw URL as an identity).
--   5. Captains are not linked to teams -> Teams.captain_user_id
--      (a logged-in captain had no path to "my team").
--   6. Tournament.status is free text   -> CHECK on the 4-value vocabulary
--      (every existing row in 02/13/15 is 'completed', so this is safe).
-- =====================================================================

USE design_project_370;


-- =====================================================================
-- 1. BRACKET STRUCTURE ON `Match`
--
-- round is 1-based from the earliest round (round 1 = QF in an 8-team
-- bracket); bracket_slot is the match's position within its round. Both
-- stay NULL-able: bulk/legacy matches have no recorded bracket position,
-- and a points-by-placement lobby series uses round as "lobby number"
-- with slot 1. The UI derives labels (QF/SF/Final) from MAX(round).
-- =====================================================================
ALTER TABLE `Match`
      ADD COLUMN round        INT NULL AFTER tournament_id
    , ADD COLUMN bracket_slot INT NULL AFTER round
    , ADD CONSTRAINT chk_match_round CHECK (round IS NULL OR round > 0)
    , ADD CONSTRAINT chk_match_slot  CHECK (bracket_slot IS NULL OR bracket_slot > 0);

-- A bracket position must be unique within its tournament's round.
-- NULLs do not collide, so unpositioned matches stay unrestricted.
ALTER TABLE `Match`
    ADD CONSTRAINT uq_match_bracket UNIQUE (tournament_id, round, bracket_slot);


-- =====================================================================
-- 2. SCORE DIRECTION ON Tournament  (the golf finding)
--
-- 'high' = more points is better (Valorant wins, TFT lobby points).
-- 'low'  = fewer is better (golf strokes, race times). Every existing
-- row is a high-scoring event, so the default backfills correctly.
-- =====================================================================
ALTER TABLE Tournament
    ADD COLUMN score_direction ENUM('high','low') NOT NULL DEFAULT 'high' AFTER format;

-- Status vocabulary. Every row 02/13/15 ever inserts is 'completed';
-- NULL stays allowed because 01 declared the column nullable.
ALTER TABLE Tournament
    ADD CONSTRAINT chk_tournament_status
        CHECK (status IS NULL OR status IN ('upcoming','live','completed','cancelled'));


-- =====================================================================
-- 3. CREATOR IDENTITY
-- =====================================================================
ALTER TABLE Creators
    ADD COLUMN display_name VARCHAR(100) NULL AFTER creator_id;


-- =====================================================================
-- 4. CAPTAIN -> TEAM LINK
--
-- The 8 captain Users in 02_insert_data.sql belonged to nothing. This
-- gives a logged-in captain a path to "my team". Nullable: bulk teams
-- and future teams need no captain on file.
-- =====================================================================
ALTER TABLE Teams
      ADD COLUMN captain_user_id INT NULL
    , ADD CONSTRAINT fk_teams_captain FOREIGN KEY (captain_user_id)
          REFERENCES Users (user_id);


-- =====================================================================
-- 5. SOLO-COMPETITOR PAYOUTS
--
-- payee_type gains 'player' (appended, so existing 'staff'/'team' rows
-- keep their values). The old two-way exclusive-arc CHECK is unnamed
-- (auto-named Payments_chk_N), so it is looked up and dropped
-- dynamically, then replaced by the three-way arc.
-- =====================================================================
ALTER TABLE Payments
      MODIFY payee_type ENUM('staff','team','player') NOT NULL
    , ADD COLUMN player_id INT NULL AFTER team_id
    , ADD CONSTRAINT fk_pay_player FOREIGN KEY (player_id)
          REFERENCES Players (player_id);

SET @arc := (SELECT cc.CONSTRAINT_NAME
             FROM information_schema.CHECK_CONSTRAINTS cc
             JOIN information_schema.TABLE_CONSTRAINTS tc
               ON  tc.CONSTRAINT_NAME   = cc.CONSTRAINT_NAME
               AND tc.CONSTRAINT_SCHEMA = cc.CONSTRAINT_SCHEMA
             WHERE cc.CONSTRAINT_SCHEMA = DATABASE()
               AND tc.TABLE_NAME        = 'Payments'
               AND tc.CONSTRAINT_TYPE   = 'CHECK'
               AND cc.CHECK_CLAUSE LIKE '%payee_type%'
             LIMIT 1);
SET @sql := CONCAT('ALTER TABLE Payments DROP CHECK ', @arc);
PREPARE drop_arc FROM @sql;
EXECUTE drop_arc;
DEALLOCATE PREPARE drop_arc;

ALTER TABLE Payments
    ADD CONSTRAINT chk_payments_payee CHECK (
        (payee_type = 'staff'  AND staff_user_id IS NOT NULL AND team_id   IS NULL AND player_id IS NULL)
     OR (payee_type = 'team'   AND team_id       IS NOT NULL AND staff_user_id IS NULL AND player_id IS NULL)
     OR (payee_type = 'player' AND player_id     IS NOT NULL AND staff_user_id IS NULL AND team_id  IS NULL));

-- A payment someone forgot to status was the exact row the outstanding
-- report exists to find (Sprint 5, test N2). New rows now start there.
ALTER TABLE Payments
    MODIFY status VARCHAR(50) NULL DEFAULT 'pending';


-- =====================================================================
-- 6. PAYMENT TRIGGERS, EXTENDED  (replaces the pair from 10_acid_fixes)
--
-- Same guarantees as before -- payee must be registered, payouts must
-- fit the pool -- but the pool cap now sums BOTH prize payee kinds, so a
-- team event and a solo event are capped identically.
-- =====================================================================
DROP TRIGGER IF EXISTS trg_payments_valid_ins;
DROP TRIGGER IF EXISTS trg_payments_valid_upd;

DELIMITER $$

CREATE TRIGGER trg_payments_valid_ins
BEFORE INSERT ON Payments FOR EACH ROW
BEGIN
    IF NEW.payee_type = 'team' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM Registration r
            JOIN Competitor   c ON c.competitor_id = r.competitor_id
            WHERE r.tournament_id = NEW.tournament_id
              AND c.team_id       = NEW.team_id
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'team is not registered for this tournament';
        END IF;
    ELSEIF NEW.payee_type = 'player' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM Registration r
            JOIN Competitor   c ON c.competitor_id = r.competitor_id
            WHERE r.tournament_id = NEW.tournament_id
              AND c.player_id     = NEW.player_id
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'player is not registered for this tournament';
        END IF;
    END IF;

    IF NEW.payee_type IN ('team','player') THEN
        IF (SELECT COALESCE(SUM(amount), 0) FROM Payments
            WHERE tournament_id = NEW.tournament_id
              AND payee_type IN ('team','player'))
           + NEW.amount
           > (SELECT prize_pool FROM Tournament WHERE tournament_id = NEW.tournament_id)
        THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'payout would exceed the tournament prize pool';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_payments_valid_upd
BEFORE UPDATE ON Payments FOR EACH ROW
BEGIN
    IF NEW.payee_type = 'team' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM Registration r
            JOIN Competitor   c ON c.competitor_id = r.competitor_id
            WHERE r.tournament_id = NEW.tournament_id
              AND c.team_id       = NEW.team_id
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'team is not registered for this tournament';
        END IF;
    ELSEIF NEW.payee_type = 'player' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM Registration r
            JOIN Competitor   c ON c.competitor_id = r.competitor_id
            WHERE r.tournament_id = NEW.tournament_id
              AND c.player_id     = NEW.player_id
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'player is not registered for this tournament';
        END IF;
    END IF;

    IF NEW.payee_type IN ('team','player') THEN
        IF (SELECT COALESCE(SUM(amount), 0) FROM Payments
            WHERE tournament_id = NEW.tournament_id
              AND payee_type IN ('team','player')
              AND payment_id <> NEW.payment_id)
           + NEW.amount
           > (SELECT prize_pool FROM Tournament WHERE tournament_id = NEW.tournament_id)
        THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'payout would exceed the tournament prize pool';
        END IF;
    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- 7. VIEW UPDATES
--
-- Each CREATE OR REPLACE below starts from the NULL-SAFE definition in
-- 12_null_fixes.sql (or 04 where 12 never touched it) and adds only the
-- new-column awareness, so running this file re-asserts the null fixes.
-- =====================================================================

-- v_outstanding_payments: now shows solo-player payees too. Everything
-- else is byte-for-byte the 12_null_fixes version.
CREATE OR REPLACE VIEW v_outstanding_payments AS
SELECT
    p.payment_id
  , p.payee_type
  , COALESCE(u_payee.full_name, tm.team_name, pl.ign, '(payee not recorded)') AS payee
  , t.name AS tournament
  , p.amount
  , COALESCE(p.status, 'unrecorded') AS status
FROM Payments p
JOIN Tournament t       ON t.tournament_id = p.tournament_id
LEFT JOIN Users u_payee ON u_payee.user_id = p.staff_user_id
LEFT JOIN Teams tm      ON tm.team_id      = p.team_id
LEFT JOIN Players pl    ON pl.player_id    = p.player_id
JOIN Membership mb      ON mb.org_id       = t.org_id
JOIN Users u            ON u.user_id       = mb.user_id
WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
  AND mb.role = 'admin'
  AND mb.left_date IS NULL
  AND COALESCE(p.status, '') <> 'paid';

-- v_my_team_payouts: a solo payout can now exist, but this view is the
-- esports-org tier and orgs own teams, so payee_type = 'team' in the ON
-- clause already excludes it correctly. No change needed -- recorded here
-- so nobody "fixes" it later.

-- v_public_standings: direction-aware ranking (the golf finding). For a
-- score_direction = 'low' event the summed points are negated inside the
-- DESC ordering, which sorts ascending -- fewest strokes first -- without
-- disturbing the NULL handling from 12_null_fixes. score_direction is
-- exposed so the UI can label the column ("points" vs "strokes").
CREATE OR REPLACE VIEW v_public_standings AS
SELECT
    t.tournament_id
  , t.name   AS tournament
  , t.format
  , t.score_direction
  , RANK() OVER (PARTITION BY t.tournament_id
                 ORDER BY CASE WHEN t.score_direction = 'low'
                               THEN -COALESCE(SUM(mp.points), 0)
                               ELSE  COALESCE(SUM(mp.points), 0) END DESC
                        , MIN(mp.placement) IS NULL
                        , MIN(mp.placement) ASC) AS standing
  , COALESCE(tm.team_name, pl.ign, '(competitor not named)') AS competitor
  , c.competitor_type
  , COUNT(*)                        AS matches_played
  , COALESCE(SUM(mp.points), 0)     AS total_points
  , MIN(mp.placement)               AS best_placement
FROM MatchParticipant mp
JOIN `Match` m       ON m.match_id      = mp.match_id
JOIN Tournament t    ON t.tournament_id = m.tournament_id
JOIN Competitor c    ON c.competitor_id = mp.competitor_id
LEFT JOIN Teams tm   ON tm.team_id   = c.team_id
LEFT JOIN Players pl ON pl.player_id = c.player_id
GROUP BY t.tournament_id, t.name, t.format, t.score_direction
       , c.competitor_id, c.competitor_type, tm.team_name, pl.ign;

-- v_deliverable_status: creators finally have a name to show.
CREATE OR REPLACE VIEW v_deliverable_status AS
SELECT
    d.deliverable_id
  , COALESCE(s.company_name, cr.display_name,
             CONCAT('creator #', cr.creator_id)) AS party
  , c.party_type
  , t.name AS tournament
  , d.description
  , d.type
  , d.due_date
  , d.status
  , d.click_count
FROM Deliverables d
JOIN Contracts c       ON c.contract_id  = d.contract_id
LEFT JOIN Sponsors s   ON s.sponsor_id   = c.sponsor_id
LEFT JOIN Creators cr  ON cr.creator_id  = c.creator_id
LEFT JOIN Tournament t ON t.tournament_id = c.tournament_id;

-- v_my_creator_assignments: adds the display name, and fixes a latent
-- defect while here -- matches_streamed counted the creator's matches
-- across ALL tournaments and repeated that total on every row. It now
-- counts only matches inside the row's own tournament.
CREATE OR REPLACE VIEW v_my_creator_assignments AS
SELECT
    cr.display_name
  , t.name AS tournament
  , ca.role
  , ca.rate
  , ca.status
  , (SELECT COUNT(*)
     FROM CreatorMatches cm
     JOIN `Match` m ON m.match_id = cm.match_id
     WHERE cm.creator_id  = cr.creator_id
       AND m.tournament_id = ca.tournament_id) AS matches_streamed
FROM Creators cr
JOIN CreatorAssignment ca ON ca.creator_id    = cr.creator_id
JOIN Tournament t         ON t.tournament_id  = ca.tournament_id
WHERE cr.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);

-- NEW: v_public_bracket -- the one read model no view provided. One row
-- per match with its bracket position, competitors and winner; the
-- winner subquery returns at most one row because uq_match_placement
-- (10_acid_fixes) makes placement 1 unique per match. Audience tier;
-- if 05_roles_and_grants.sql is applied, grant it alongside
-- v_public_schedule:  GRANT SELECT ON v_public_bracket TO 'role_audience';
CREATE OR REPLACE VIEW v_public_bracket AS
SELECT
    t.tournament_id
  , t.name AS tournament
  , m.match_id
  , m.round
  , m.bracket_slot
  , m.scheduled_time
  , m.final_score
  , (SELECT GROUP_CONCAT(COALESCE(tm2.team_name, pl2.ign, '(competitor not named)')
                         ORDER BY mp2.placement IS NULL, mp2.placement
                         SEPARATOR ' vs ')
     FROM MatchParticipant mp2
     JOIN Competitor c2    ON c2.competitor_id = mp2.competitor_id
     LEFT JOIN Teams tm2   ON tm2.team_id   = c2.team_id
     LEFT JOIN Players pl2 ON pl2.player_id = c2.player_id
     WHERE mp2.match_id = m.match_id)                        AS competitors
  , (SELECT COALESCE(tm3.team_name, pl3.ign)
     FROM MatchParticipant mp3
     JOIN Competitor c3    ON c3.competitor_id = mp3.competitor_id
     LEFT JOIN Teams tm3   ON tm3.team_id   = c3.team_id
     LEFT JOIN Players pl3 ON pl3.player_id = c3.player_id
     WHERE mp3.match_id = m.match_id
       AND mp3.placement = 1)                                AS winner
FROM `Match` m
JOIN Tournament t ON t.tournament_id = m.tournament_id;


-- =====================================================================
-- VERIFY
-- =====================================================================
SELECT 'ui readiness applied' AS status
     , (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND ((TABLE_NAME = 'Match'      AND COLUMN_NAME IN ('round','bracket_slot'))
            OR (TABLE_NAME = 'Tournament' AND COLUMN_NAME = 'score_direction')
            OR (TABLE_NAME = 'Creators'   AND COLUMN_NAME = 'display_name')
            OR (TABLE_NAME = 'Teams'      AND COLUMN_NAME = 'captain_user_id')
            OR (TABLE_NAME = 'Payments'   AND COLUMN_NAME = 'player_id')))   AS new_columns   -- expect 6
     , (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
        WHERE CONSTRAINT_SCHEMA = DATABASE()
          AND CONSTRAINT_NAME IN ('chk_payments_payee','chk_tournament_status'
                                 ,'uq_match_bracket','fk_teams_captain'))    AS new_constraints -- expect 4
     , (SELECT COUNT(*) FROM information_schema.VIEWS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'v_public_bracket')                               AS new_views;     -- expect 1

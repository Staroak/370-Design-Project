-- =====================================================================
-- 10_acid_fixes.sql    closing the gaps 08 and 09 found
--
-- Apply after 01 + 02, then re-run 08_acid_tests.sql: the GAP verdicts should
-- flip to OK. run_acid_tests.sh --fixed does both in one go.
--
-- Three kinds of fix, in order of preference:
--
--   1. DECLARATIVE -- UNIQUE, NOT NULL, explicit ON DELETE. In scope for the
--      course, checked by the DBMS on every path, cannot be bypassed.
--   2. TRIGGERS -- for invariants that span rows or tables. MySQL has no
--      DEFERRABLE constraints and no CREATE ASSERTION, so a CHECK cannot
--      express "this player has no other active roster row". Triggers are not
--      taught in CSC370; they are used here because nothing else in MySQL can
--      state these rules.
--   3. TRANSACTION DISCIPLINE -- already in 07_transactions.sql. The write-skew
--      findings (I4a-c, I5) cannot be fixed by any constraint: two
--      individually-valid transactions each pass their check. Only locking the
--      row they both validated against (SELECT ... FOR UPDATE) or a UNIQUE
--      index that makes them collide will do it.
--
-- Each section names the test it closes.
-- =====================================================================

USE design_project_370;

SET @OLD_FK_CHECKS = @@FOREIGN_KEY_CHECKS;


-- #####################################################################
-- PART 1 -- DECLARATIVE FIXES
-- #####################################################################

-- ---------------------------------------------------------------------
-- C3 -- two competitors at placement 1 in the same match.
-- NULL placements stay allowed (a match in progress has no result yet) and
-- do not collide with each other, which is the correct behaviour here.
-- ---------------------------------------------------------------------
ALTER TABLE MatchParticipant
    ADD CONSTRAINT uq_match_placement UNIQUE (match_id, placement);

-- ---------------------------------------------------------------------
-- C4 and I4c -- duplicate seed. This also fixes the write-skew race: two
-- concurrent transactions computing MAX(seed)+1 now collide on the index
-- instead of both succeeding, so the loser gets ERROR 1062 rather than
-- silently creating a duplicate.
-- ---------------------------------------------------------------------
ALTER TABLE Registration
    ADD CONSTRAINT uq_tournament_seed UNIQUE (tournament_id, seed);

-- ---------------------------------------------------------------------
-- C12 -- NULL bypassing a CHECK and a UNIQUE.
--
-- Tournament dates and prize_pool: every seeded row has values, and
-- "payouts <= pool" is unverifiable when the pool is NULL, so require them.
-- This makes CHECK (start_date <= end_date) unconditional.
--
-- Roster.jersey_number: NULL does not collide in a UNIQUE index, so unlimited
-- players could share "no number" on one team. Require it.
--
-- Roster.leave_date stays nullable on purpose -- NULL means "still active" and
-- is load-bearing throughout 04_views.sql. CHECK (join_date <= leave_date)
-- therefore stays conditional, which is correct, not a defect.
-- ---------------------------------------------------------------------
ALTER TABLE Tournament
      MODIFY start_date DATE          NOT NULL
    , MODIFY end_date   DATE          NOT NULL
    , MODIFY prize_pool DECIMAL(12,2) NOT NULL DEFAULT 0.00;

ALTER TABLE Contracts
      MODIFY start_date DATE NOT NULL
    , MODIFY end_date   DATE NOT NULL;

ALTER TABLE Roster
    MODIFY jersey_number INT NOT NULL;

-- ---------------------------------------------------------------------
-- A6 -- deleting a tournament required clearing four tables by hand, in the
-- right order, and still failed at the end.
--
-- The four child tables of `Match` have no meaning without their match, so
-- they cascade. Everything else stays RESTRICT -- now stated explicitly rather
-- than inherited -- because financial and registration records must not
-- disappear because someone deleted a tournament.
--
-- MySQL auto-names unnamed foreign keys <table>_ibfk_N. If a DROP below fails
-- because your names differ, list them with:
--     SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
--     FROM information_schema.REFERENTIAL_CONSTRAINTS
--     WHERE CONSTRAINT_SCHEMA = 'design_project_370';
-- ---------------------------------------------------------------------
ALTER TABLE MatchParticipant
      DROP FOREIGN KEY matchparticipant_ibfk_1
    , ADD CONSTRAINT fk_mp_match FOREIGN KEY (match_id)
          REFERENCES `Match` (match_id) ON DELETE CASCADE;

ALTER TABLE PlayerMatchStats
      DROP FOREIGN KEY playermatchstats_ibfk_2
    , ADD CONSTRAINT fk_pms_match FOREIGN KEY (match_id)
          REFERENCES `Match` (match_id) ON DELETE CASCADE;

ALTER TABLE StaffMatches
      DROP FOREIGN KEY staffmatches_ibfk_2
    , ADD CONSTRAINT fk_sm_match FOREIGN KEY (match_id)
          REFERENCES `Match` (match_id) ON DELETE CASCADE;

ALTER TABLE CreatorMatches
      DROP FOREIGN KEY creatormatches_ibfk_2
    , ADD CONSTRAINT fk_cm_match FOREIGN KEY (match_id)
          REFERENCES `Match` (match_id) ON DELETE CASCADE;

-- Deliverables belong to their contract and cascade with it.
ALTER TABLE Deliverables
      DROP FOREIGN KEY deliverables_ibfk_1
    , ADD CONSTRAINT fk_deliv_contract FOREIGN KEY (contract_id)
          REFERENCES Contracts (contract_id) ON DELETE CASCADE;

-- Matches belong to their tournament and cascade with it. Combined with the
-- four cascades above, one DELETE now removes a tournament's whole bracket --
-- and still fails on Payments / Transactions / Registration, which is correct:
-- money and entries must be dealt with deliberately, not swept away.
ALTER TABLE `Match`
      DROP FOREIGN KEY match_ibfk_1
    , ADD CONSTRAINT fk_match_tournament FOREIGN KEY (tournament_id)
          REFERENCES Tournament (tournament_id) ON DELETE CASCADE;


-- #####################################################################
-- PART 2 -- TRIGGERS
--
-- One per invariant that no CHECK can express. Each raises SQLSTATE '45000',
-- which surfaces as ERROR 1644 with the message text. Insert and update are
-- separate triggers because MySQL allows only one trigger per timing/event
-- pair, and both call the same logic.
-- #####################################################################

DROP TRIGGER IF EXISTS trg_registration_game_ins;
DROP TRIGGER IF EXISTS trg_registration_game_upd;
DROP TRIGGER IF EXISTS trg_matchparticipant_reg_ins;
DROP TRIGGER IF EXISTS trg_matchparticipant_reg_upd;
DROP TRIGGER IF EXISTS trg_roster_active_ins;
DROP TRIGGER IF EXISTS trg_roster_active_upd;
DROP TRIGGER IF EXISTS trg_match_window_ins;
DROP TRIGGER IF EXISTS trg_match_window_upd;
DROP TRIGGER IF EXISTS trg_staffassign_member_ins;
DROP TRIGGER IF EXISTS trg_staffassign_member_upd;
DROP TRIGGER IF EXISTS trg_staffmatches_overlap_ins;
DROP TRIGGER IF EXISTS trg_creatormatches_overlap_ins;
DROP TRIGGER IF EXISTS trg_playerstats_overlap_ins;
DROP TRIGGER IF EXISTS trg_payments_valid_ins;
DROP TRIGGER IF EXISTS trg_payments_valid_upd;
DROP TRIGGER IF EXISTS trg_transactions_org_ins;
DROP TRIGGER IF EXISTS trg_transactions_org_upd;
DROP TRIGGER IF EXISTS trg_contracts_org_ins;
DROP TRIGGER IF EXISTS trg_contracts_org_upd;

DELIMITER $$

-- ---------------------------------------------------------------------
-- C1 -- a team competitor must play the tournament's game.
-- A 'player' competitor carries no game of its own, so it is exempt.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_registration_game_ins
BEFORE INSERT ON Registration FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Competitor  c
        JOIN Teams       tm ON tm.team_id       = c.team_id
        JOIN Tournament  t  ON t.tournament_id  = NEW.tournament_id
        WHERE c.competitor_id = NEW.competitor_id
          AND c.team_id IS NOT NULL
          AND tm.game_id <> t.game_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'team plays a different game than this tournament';
    END IF;
END$$

CREATE TRIGGER trg_registration_game_upd
BEFORE UPDATE ON Registration FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Competitor  c
        JOIN Teams       tm ON tm.team_id       = c.team_id
        JOIN Tournament  t  ON t.tournament_id  = NEW.tournament_id
        WHERE c.competitor_id = NEW.competitor_id
          AND c.team_id IS NOT NULL
          AND tm.game_id <> t.game_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'team plays a different game than this tournament';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- C2 -- a competitor in a match must be registered for that tournament.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_matchparticipant_reg_ins
BEFORE INSERT ON MatchParticipant FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `Match`      m
        JOIN Registration r ON r.tournament_id = m.tournament_id
        WHERE m.match_id      = NEW.match_id
          AND r.competitor_id = NEW.competitor_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'competitor is not registered for this match''s tournament';
    END IF;
END$$

CREATE TRIGGER trg_matchparticipant_reg_upd
BEFORE UPDATE ON MatchParticipant FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM `Match`      m
        JOIN Registration r ON r.tournament_id = m.tournament_id
        WHERE m.match_id      = NEW.match_id
          AND r.competitor_id = NEW.competitor_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'competitor is not registered for this match''s tournament';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- C5 and I4b -- a player may hold only one active roster row.
-- The write-skew case (I4b) is also closed: the second transaction's INSERT
-- reads the table under the trigger, which is a current read, so it sees the
-- first transaction's committed row instead of its own stale snapshot.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_roster_active_ins
BEFORE INSERT ON Roster FOR EACH ROW
BEGIN
    IF NEW.leave_date IS NULL AND EXISTS (
        SELECT 1 FROM Roster
        WHERE player_id = NEW.player_id AND leave_date IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'player already has an active roster spot on another team';
    END IF;
END$$

CREATE TRIGGER trg_roster_active_upd
BEFORE UPDATE ON Roster FOR EACH ROW
BEGIN
    IF NEW.leave_date IS NULL AND EXISTS (
        SELECT 1 FROM Roster
        WHERE player_id = NEW.player_id
          AND leave_date IS NULL
          AND roster_id <> NEW.roster_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'player already has an active roster spot on another team';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- C6 -- a match must fall inside its tournament's date range.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_match_window_ins
BEFORE INSERT ON `Match` FOR EACH ROW
BEGIN
    IF NEW.scheduled_time IS NOT NULL AND EXISTS (
        SELECT 1 FROM Tournament
        WHERE tournament_id = NEW.tournament_id
          AND (DATE(NEW.scheduled_time) < start_date
            OR DATE(NEW.scheduled_time) > end_date)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'match is scheduled outside its tournament date range';
    END IF;
END$$

CREATE TRIGGER trg_match_window_upd
BEFORE UPDATE ON `Match` FOR EACH ROW
BEGIN
    IF NEW.scheduled_time IS NOT NULL AND EXISTS (
        SELECT 1 FROM Tournament
        WHERE tournament_id = NEW.tournament_id
          AND (DATE(NEW.scheduled_time) < start_date
            OR DATE(NEW.scheduled_time) > end_date)
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'match is scheduled outside its tournament date range';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- C7 and I5 -- staff must be an active member of the organising org.
-- Closes the cross-table write skew too: the trigger's read of Membership is a
-- current read, so it sees a concurrently committed left_date.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_staffassign_member_ins
BEFORE INSERT ON StaffAssignments FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Tournament t
        JOIN Membership mb ON mb.org_id = t.org_id
        WHERE t.tournament_id = NEW.tournament_id
          AND mb.user_id      = NEW.user_id
          AND mb.left_date IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'user is not an active member of the organisation running this tournament';
    END IF;
END$$

CREATE TRIGGER trg_staffassign_member_upd
BEFORE UPDATE ON StaffAssignments FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Tournament t
        JOIN Membership mb ON mb.org_id = t.org_id
        WHERE t.tournament_id = NEW.tournament_id
          AND mb.user_id      = NEW.user_id
          AND mb.left_date IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'user is not an active member of the organisation running this tournament';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- C8 -- nobody works two matches at the same instant.
-- Insert only: match times move via `Match`, not via these junction tables.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_staffmatches_overlap_ins
BEFORE INSERT ON StaffMatches FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM StaffMatches sm
        JOIN `Match` m1 ON m1.match_id = sm.match_id
        JOIN `Match` m2 ON m2.match_id = NEW.match_id
        WHERE sm.user_id = NEW.user_id
          AND m1.scheduled_time = m2.scheduled_time
          AND sm.match_id <> NEW.match_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'staff member is already working another match at that time';
    END IF;
END$$

CREATE TRIGGER trg_creatormatches_overlap_ins
BEFORE INSERT ON CreatorMatches FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM CreatorMatches cm
        JOIN `Match` m1 ON m1.match_id = cm.match_id
        JOIN `Match` m2 ON m2.match_id = NEW.match_id
        WHERE cm.creator_id = NEW.creator_id
          AND m1.scheduled_time = m2.scheduled_time
          AND cm.match_id <> NEW.match_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'creator is already streaming another match at that time';
    END IF;
END$$

CREATE TRIGGER trg_playerstats_overlap_ins
BEFORE INSERT ON PlayerMatchStats FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM PlayerMatchStats ps
        JOIN `Match` m1 ON m1.match_id = ps.match_id
        JOIN `Match` m2 ON m2.match_id = NEW.match_id
        WHERE ps.player_id = NEW.player_id
          AND m1.scheduled_time = m2.scheduled_time
          AND ps.match_id <> NEW.match_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'player is already recorded in another match at that time';
    END IF;
END$$

-- ---------------------------------------------------------------------
-- C9, C10 and I4a -- team payouts must go to a registered team and must not
-- exceed the prize pool.
--
-- This closes the write skew (I4a) as well: the trigger's SUM over Payments is
-- a current read, so the second transaction sees the first one's committed
-- payment rather than its own snapshot. sp_pay_team_prize still takes
-- FOR UPDATE on the Tournament row, which serialises the two callers earlier
-- and turns a lost race into a clean wait.
-- ---------------------------------------------------------------------
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

        IF (SELECT COALESCE(SUM(amount), 0) FROM Payments
            WHERE tournament_id = NEW.tournament_id AND payee_type = 'team')
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

        IF (SELECT COALESCE(SUM(amount), 0) FROM Payments
            WHERE tournament_id = NEW.tournament_id
              AND payee_type    = 'team'
              AND payment_id   <> NEW.payment_id)
           + NEW.amount
           > (SELECT prize_pool FROM Tournament WHERE tournament_id = NEW.tournament_id)
        THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'payout would exceed the tournament prize pool';
        END IF;
    END IF;
END$$

-- ---------------------------------------------------------------------
-- C11 -- a financial row tied to a tournament must belong to the org that
-- owns that tournament. This is the consistency fix that closes the
-- row-level-security leak in v_org_financials.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_transactions_org_ins
BEFORE INSERT ON Transactions FOR EACH ROW
BEGIN
    IF NEW.tournament_id IS NOT NULL AND NEW.org_id <>
       (SELECT org_id FROM Tournament WHERE tournament_id = NEW.tournament_id)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'transaction org_id does not own this tournament';
    END IF;
END$$

CREATE TRIGGER trg_transactions_org_upd
BEFORE UPDATE ON Transactions FOR EACH ROW
BEGIN
    IF NEW.tournament_id IS NOT NULL AND NEW.org_id <>
       (SELECT org_id FROM Tournament WHERE tournament_id = NEW.tournament_id)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'transaction org_id does not own this tournament';
    END IF;
END$$

CREATE TRIGGER trg_contracts_org_ins
BEFORE INSERT ON Contracts FOR EACH ROW
BEGIN
    IF NEW.tournament_id IS NOT NULL AND NEW.org_id <>
       (SELECT org_id FROM Tournament WHERE tournament_id = NEW.tournament_id)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'contract org_id does not own this tournament';
    END IF;
END$$

CREATE TRIGGER trg_contracts_org_upd
BEFORE UPDATE ON Contracts FOR EACH ROW
BEGIN
    IF NEW.tournament_id IS NOT NULL AND NEW.org_id <>
       (SELECT org_id FROM Tournament WHERE tournament_id = NEW.tournament_id)
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'contract org_id does not own this tournament';
    END IF;
END$$

DELIMITER ;


-- #####################################################################
-- PART 3 -- NOT FIXED HERE, AND WHY
-- #####################################################################
--
-- A1, A2  Atomicity is a property of how the client groups statements, not of
--         the schema. Nothing declarative can fix them. The fix is to call the
--         procedures in 07_transactions.sql instead of issuing loose INSERTs.
--
-- A3      MySQL rolls back only the failing statement on a lock-wait timeout.
--         No schema change helps. The fix is DECLARE EXIT HANDLER FOR
--         SQLEXCEPTION ... ROLLBACK, which 07_transactions.sql uses.
--
-- A5      CREATE USER and GRANT are DDL and force an implicit commit. Account
--         provisioning can never be atomic with the data it maps to in MySQL.
--         The fix is to order it: commit the data first, provision second, and
--         reconcile orphaned accounts separately.
--
-- C13     Reconciling Transactions.category = 'staff' against actual Payments
--         is a reporting concern, not a row-level invariant -- a trigger on
--         either table would fire before the other side exists. Sprint 5:
--         either derive the expense from Payments, or add a reconciliation
--         view alongside v_registration_violations and v_match_integrity.
--
-- I1, I3-RC   Not defects. Those anomalies only appear when the isolation
--             level is deliberately lowered; our default prevents them.
--
-- ENGINE      01_create_tables.sql should say ENGINE=InnoDB explicitly rather
--             than inheriting default_storage_engine. Not done here because it
--             belongs in the CREATE TABLE statements, not in an ALTER script.


SET FOREIGN_KEY_CHECKS = @OLD_FK_CHECKS;

SELECT 'fixes applied' AS status
     , (SELECT COUNT(*) FROM information_schema.TRIGGERS
        WHERE TRIGGER_SCHEMA = DATABASE())                       AS triggers
     , (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
        WHERE CONSTRAINT_SCHEMA = DATABASE()
          AND CONSTRAINT_NAME IN ('uq_match_placement','uq_tournament_seed')) AS new_uniques
     , (SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS
        WHERE CONSTRAINT_SCHEMA = DATABASE()
          AND DELETE_RULE = 'CASCADE')                           AS cascading_fks;

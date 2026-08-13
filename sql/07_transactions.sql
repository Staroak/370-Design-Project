USE design_project_370;

DROP PROCEDURE IF EXISTS sp_pay_team_prize;
DROP PROCEDURE IF EXISTS sp_register_team;
DROP PROCEDURE IF EXISTS sp_record_placement;
DROP PROCEDURE IF EXISTS sp_onboard_org;


-- =====================================================================
-- T1  sp_pay_team_prize -- pay a team its prize and book the expense
--
-- Guards the invariants that tests A1, C9, C10 and I4a break:
--   * the Payments row and its matching Transactions row live or die together
--   * total team payouts never exceed Tournament.prize_pool
--   * the team actually competed in that tournament
-- =====================================================================
DELIMITER $$
CREATE PROCEDURE sp_pay_team_prize (
      IN p_team_id        INT
    , IN p_tournament_id  INT
    , IN p_amount         DECIMAL(12,2)
)
BEGIN
    DECLARE v_org_id  INT           DEFAULT NULL;
    DECLARE v_pool    DECIMAL(12,2) DEFAULT NULL;
    DECLARE v_paid    DECIMAL(12,2) DEFAULT 0;

    -- Any error at all -- a CHECK failure, an FK failure, a SIGNAL below, a
    -- deadlock -- undoes the whole procedure and is then re-raised. Without
    -- this, MySQL rolls back only the failing STATEMENT (test A3).
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- FOR UPDATE is what makes the headroom check below safe under
    -- concurrency. Two sessions paying out of the same pool now queue here
    -- instead of both reading the same balance and both passing.
    SELECT org_id, prize_pool
      INTO v_org_id, v_pool
    FROM Tournament
    WHERE tournament_id = p_tournament_id
    FOR UPDATE;

    IF v_pool IS NULL THEN
        -- Schema gap worth fixing in Sprint 5: Tournament.prize_pool is
        -- nullable, so "payouts <= pool" is unverifiable for some rows.
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'unknown tournament, or its prize_pool is NULL';
    END IF;

    -- Validate the payee BEFORE the money. Order matters for the test suite:
    -- with the checks the other way round, test C10-FIX (pay a team that never
    -- entered tournament 2, whose pool is already exhausted) would be refused
    -- by the headroom check and would appear to pass for the wrong reason.
    IF NOT EXISTS (
        SELECT 1
        FROM Registration r
        JOIN Competitor   c ON c.competitor_id = r.competitor_id
        WHERE r.tournament_id = p_tournament_id
          AND c.team_id       = p_team_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'team is not registered for this tournament';
    END IF;

    SELECT COALESCE(SUM(amount), 0)
      INTO v_paid
    FROM Payments
    WHERE tournament_id = p_tournament_id
      AND payee_type    = 'team';

    IF v_paid + p_amount > v_pool THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'payout would exceed the tournament prize pool';
    END IF;

    INSERT INTO Payments
        (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
    VALUES
        ('team', NULL, p_team_id, p_tournament_id, p_amount, 'paid', CURRENT_DATE);

    -- NOTE on a convention clash in our own data: 02_insert_data.sql books
    -- prize payouts as ONE aggregate expense per tournament (5000 for
    -- tournament 1), whereas this procedure books one expense per payment.
    -- Both are defensible, mixing them double-counts. Pick one in Sprint 5.
    INSERT INTO Transactions
        (org_id, tournament_id, type, category, amount, date)
    VALUES
        (v_org_id, p_tournament_id, 'expense', 'prize payout', p_amount, CURRENT_DATE);

    COMMIT;
END$$
DELIMITER ;


-- =====================================================================
-- T2  sp_register_team -- enter a team into a tournament
--
-- Guards the invariants that tests A2, C1, C4 and I4c break:
--   * Players / Competitor / Registration are created together or not at all
--   * the team plays the same game as the tournament
--   * the seed is free
-- =====================================================================
DELIMITER $$
CREATE PROCEDURE sp_register_team (
      IN p_team_id        INT
    , IN p_tournament_id  INT
    , IN p_seed           INT
)
BEGIN
    DECLARE v_competitor_id  INT DEFAULT NULL;
    DECLARE v_team_game      INT DEFAULT NULL;
    DECLARE v_tourn_game     INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Lock the tournament first: it is the row every check below is relative
    -- to, so locking it serialises two concurrent registrations.
    SELECT game_id INTO v_tourn_game
    FROM Tournament
    WHERE tournament_id = p_tournament_id
    FOR UPDATE;

    SELECT game_id INTO v_team_game
    FROM Teams
    WHERE team_id = p_team_id;

    IF v_tourn_game IS NULL OR v_team_game IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'unknown team or tournament';
    END IF;

    -- The APP/TRIGGER note on Registration in 01_create_tables.sql.
    IF v_team_game <> v_tourn_game THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'team plays a different game than this tournament';
    END IF;

    IF p_seed IS NOT NULL AND EXISTS (
        SELECT 1 FROM Registration
        WHERE tournament_id = p_tournament_id AND seed = p_seed
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'seed already taken in this tournament';
    END IF;

    -- Competitor.team_id is UNIQUE, so a team has at most one competitor row
    -- for its whole life. Reuse it if it exists, create it if not. This is the
    -- multi-table insert that test A2 leaves half-finished.
    SELECT competitor_id INTO v_competitor_id
    FROM Competitor
    WHERE team_id = p_team_id;

    IF v_competitor_id IS NULL THEN
        INSERT INTO Competitor (competitor_type, team_id, player_id)
        VALUES ('team', p_team_id, NULL);
        SET v_competitor_id = LAST_INSERT_ID();
    END IF;

    INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
    VALUES (v_competitor_id, p_tournament_id, CURRENT_DATE, p_seed);

    COMMIT;
END$$
DELIMITER ;


-- =====================================================================
-- T3  sp_record_placement -- record one competitor's result in a match
--
-- Guards the invariants that tests C2 and C3 break:
--   * the competitor was registered for that match's tournament
--   * no two competitors share a placement in the same match
-- =====================================================================
DELIMITER $$
CREATE PROCEDURE sp_record_placement (
      IN p_match_id       INT
    , IN p_competitor_id  INT
    , IN p_placement      INT
    , IN p_points         INT
)
BEGIN
    DECLARE v_tournament_id INT DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT tournament_id INTO v_tournament_id
    FROM `Match`
    WHERE match_id = p_match_id
    FOR UPDATE;

    IF v_tournament_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'unknown match';
    END IF;

    -- Nothing in the schema links MatchParticipant back to Registration, which
    -- is how a solo TFT player can appear in a Valorant final (test C2).
    IF NOT EXISTS (
        SELECT 1 FROM Registration
        WHERE tournament_id = v_tournament_id
          AND competitor_id = p_competitor_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'competitor is not registered for this match''s tournament';
    END IF;

    IF p_placement IS NOT NULL AND EXISTS (
        SELECT 1 FROM MatchParticipant
        WHERE match_id = p_match_id AND placement = p_placement
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'that placement is already taken in this match';
    END IF;

    INSERT INTO MatchParticipant (match_id, competitor_id, placement, points)
    VALUES (p_match_id, p_competitor_id, p_placement, p_points);

    COMMIT;
END$$
DELIMITER ;


-- =====================================================================
-- T4  sp_onboard_org -- create an organizer and its first admin member
--
-- Deliberately contains NO DDL. Test A5 shows that putting CREATE USER or
-- GRANT in here would force an implicit COMMIT and make the ROLLBACK a no-op.
-- Account provisioning is therefore a SEPARATE, non-atomic step, run after
-- this procedure succeeds and returns the db_username it expects.
-- =====================================================================
DELIMITER $$
CREATE PROCEDURE sp_onboard_org (
      IN p_org_name     VARCHAR(255)
    , IN p_org_email    VARCHAR(255)
    , IN p_region       VARCHAR(100)
    , IN p_admin_name   VARCHAR(255)
    , IN p_admin_email  VARCHAR(255)
    , IN p_db_username  VARCHAR(64)
)
BEGIN
    DECLARE v_org_id   INT;
    DECLARE v_user_id  INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO Organization (org_name, contact_email, created_date, region)
    VALUES (p_org_name, p_org_email, CURRENT_DATE, p_region);
    SET v_org_id = LAST_INSERT_ID();

    INSERT INTO Users (full_name, email, password, db_username)
    VALUES (p_admin_name, p_admin_email, 'CHANGE_ME', p_db_username);
    SET v_user_id = LAST_INSERT_ID();

    INSERT INTO Membership (user_id, org_id, role, joined_date)
    VALUES (v_user_id, v_org_id, 'admin', CURRENT_DATE);

    COMMIT;

    -- Caller must now run, OUTSIDE this transaction:
    --   CREATE USER '<p_db_username>'@'localhost' IDENTIFIED BY '...';
    --   GRANT role_admin TO '<p_db_username>'@'localhost';
    SELECT v_org_id AS org_id, v_user_id AS user_id, p_db_username AS provision_account;
END$$
DELIMITER ;


SELECT 'procedures created' AS status, COUNT(*) AS n
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_NAME IN ('sp_pay_team_prize','sp_register_team',
                       'sp_record_placement','sp_onboard_org');

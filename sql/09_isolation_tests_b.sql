-- =====================================================================
-- 09_isolation_tests_b.sql    SESSION B     (pair: 09_isolation_tests_a.sql)
--
-- Run this in the SECOND terminal:
--     mysql -u root -p design_project_370
--     SET autocommit = 0;
--
-- Paste only the [X-B#] blocks, in numeric order, alternating with session A.
-- Read 09_isolation_tests_a.sql first -- it carries the explanation of each
-- test, the setup, and every reset. This file is just B's half of the schedule.
-- =====================================================================

USE design_project_370;
SET autocommit = 0;


-- #####################################################################
-- A3 -- LOCK-WAIT TIMEOUT ROLLS BACK ONLY THE FAILING STATEMENT
-- #####################################################################

-- [A3-B2] run after A's [A3-A1]. A short timeout so this returns quickly.
SET SESSION innodb_lock_wait_timeout = 3;
START TRANSACTION;

-- succeeds
INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('staff', 12, NULL, 1, 400.00, 'pending', NULL);

-- blocks on A's lock, then fails: ERROR 1205 lock wait timeout exceeded
UPDATE Tournament SET prize_pool = 6000.00 WHERE tournament_id = 1;

-- MySQL rolled back only the UPDATE. The transaction is still open and the
-- INSERT is still in it, so a script that ignores the error commits anyway.
COMMIT;

SELECT 'A3' AS test
     , (SELECT prize_pool FROM Tournament WHERE tournament_id = 1) AS pool_unchanged
     , IF(COUNT(*) > 0
        , 'GAP -- payment committed without the pool increase that justified it'
        , 'OK -- whole transaction was rolled back') AS verdict
FROM Payments
WHERE tournament_id = 1 AND staff_user_id = 12 AND amount = 400.00;
COMMIT;

-- [A3-B4] reset, after A's [A3-A3]
DELETE FROM Payments
WHERE tournament_id = 1 AND staff_user_id = 12 AND amount = 400.00 AND status = 'pending';
COMMIT;
SET SESSION innodb_lock_wait_timeout = DEFAULT;


-- #####################################################################
-- A4 -- DEADLOCK ROLLS BACK THE ENTIRE TRANSACTION
-- #####################################################################

-- [A4-B2] run after A's [A4-A1]. Same two rows, opposite order.
START TRANSACTION;
UPDATE Payments SET status = 'paid' WHERE payment_id = 3;

-- [A4-B3] run after A starts its [A4-A3] and blocks.
-- One of the two sessions now gets ERROR 1213 and loses its ENTIRE
-- transaction, not just this statement. Contrast with A3.
UPDATE Tournament SET status = 'completed' WHERE tournament_id = 2;

-- [A4-B4] whichever session survived, undo it
ROLLBACK;
SELECT 'A4' AS test
     , (SELECT status FROM Payments WHERE payment_id = 3) AS payment_status_should_be_pending
     , 'see which session reported ERROR 1213' AS note;
COMMIT;


-- #####################################################################
-- I1 -- DIRTY READ
-- #####################################################################

-- [I1-B2] run after A's [I1-A1]. This is a DELIBERATE RELAXATION of a
-- setting, not a defect in our schema -- it shows what our REPEATABLE READ
-- default protects us from. Reset at the end of the block.
SET SESSION transaction_isolation = 'READ-UNCOMMITTED';
START TRANSACTION;

SELECT 'I1' AS test
     , SUM(CASE WHEN type = 'revenue' THEN amount ELSE 0 END)
     - SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS profit_reported
     , IF(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) > 40000
        , 'GAP -- reported a loss from a row A never committed (dirty read)'
        , 'OK -- did not see A uncommitted write') AS verdict
FROM Transactions WHERE tournament_id = 1;
COMMIT;

SET SESSION transaction_isolation = DEFAULT;

-- [I1-B4] optional: after A rolls back, re-run the same read at our real
-- default to show the dirty row was never there.
START TRANSACTION;
SELECT 'I1 at REPEATABLE READ' AS step
     , SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expense_total
FROM Transactions WHERE tournament_id = 1;
COMMIT;


-- #####################################################################
-- I2 -- LOST UPDATE
-- #####################################################################

-- [I2-B2] run after A's [I2-A1]. Both sessions have now read 3200.
START TRANSACTION;
SELECT 'I2-B read' AS step, click_count FROM Deliverables WHERE deliverable_id = 5;

-- [I2-B4] run after A's [I2-A3]. B also computed 3200 + 1. This blocks on A's
-- row lock, then applies -- overwriting A click with the same value.
UPDATE Deliverables SET click_count = 3201 WHERE deliverable_id = 5;
COMMIT;
-- Now go back to A for [I2-A5].


-- #####################################################################
-- I3 -- READ SKEW
-- #####################################################################

-- [I3-B1] START HERE for I3. Deliberate relaxation again: READ COMMITTED, to
-- show the anomaly our default prevents.
SET SESSION transaction_isolation = 'READ-COMMITTED';
START TRANSACTION;
SELECT 'I3-B revenue' AS step, SUM(amount) AS revenue
FROM Transactions WHERE tournament_id = 1 AND type = 'revenue';
-- now switch to A for [I3-A2]

-- [I3-B3] run after A commits its transfer
SELECT 'I3' AS test
     , (SELECT SUM(amount) FROM Transactions
        WHERE tournament_id = 1 AND type = 'revenue') AS revenue_now
     , SUM(amount) AS expenses_now
     , 'compare against the revenue read in [I3-B1]: the profit computed from '
       'the two reads matches no single state of the table' AS note
FROM Transactions WHERE tournament_id = 1 AND type = 'expense';
COMMIT;

-- [I3-B4] now the same schedule at our actual default. Re-run [I3-A2] with a
-- fresh transfer while this transaction is open; both reads stay consistent.
SET SESSION transaction_isolation = DEFAULT;
START TRANSACTION;
SELECT 'I3 at REPEATABLE READ' AS step
     , SUM(amount) AS revenue
FROM Transactions WHERE tournament_id = 1 AND type = 'revenue';
-- (A runs its transfer here)
SELECT 'I3 at REPEATABLE READ' AS step
     , SUM(amount) AS revenue_reread
FROM Transactions WHERE tournament_id = 1 AND type = 'revenue';
COMMIT;
-- Same number twice = REPEATABLE READ is earning its keep. Then A runs
-- [I3-A5] to reset.


-- #####################################################################
-- I4a -- WRITE SKEW: PRIZE POOL OVERDRAWN
-- Nothing relaxed. Our real default isolation level.
-- #####################################################################

-- [I4a-B3] run after A's [I4a-A2]. B sees the same 1000 of headroom A saw.
START TRANSACTION;
SELECT (SELECT prize_pool FROM Tournament WHERE tournament_id = 2)
     - COALESCE(SUM(amount), 0) AS headroom_seen_by_B
FROM Payments WHERE tournament_id = 2 AND payee_type = 'team';

-- [I4a-B5] run after A's [I4a-A4]. 1000 <= 1000, so B proceeds too.
INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('team', NULL, 3, 2, 1000.00, 'paid', CURRENT_DATE);
COMMIT;
-- Now go back to A for [I4a-A6]. Total paid is 4000 against a 3000 pool.


-- #####################################################################
-- I4b -- WRITE SKEW: PLAYER ACTIVE ON TWO TEAMS
-- #####################################################################

-- [I4b-B2] run after A's [I4b-A1]. Both sessions saw zero active teams.
START TRANSACTION;
SELECT COUNT(*) AS active_teams_seen_by_B
FROM Roster WHERE player_id = 47 AND leave_date IS NULL;

-- [I4b-B4] run after A's [I4b-A3]. Different team, so no row collides.
INSERT INTO Roster (player_id, team_id, join_date, leave_date, salary, jersey_number)
VALUES (47, 6, CURRENT_DATE, NULL, 900.00, 10);
COMMIT;
-- Now go back to A for [I4b-A5].


-- #####################################################################
-- I4c -- WRITE SKEW: DUPLICATE SEED FROM MAX(seed)+1
-- #####################################################################

-- [I4c-B2] run after A's [I4c-A1]. Both sessions compute 5.
START TRANSACTION;
SELECT COALESCE(MAX(seed), 0) + 1 AS next_seed_seen_by_B
FROM Registration WHERE tournament_id = 2;

-- [I4c-B4] run after A's [I4c-A3]. Different competitor, so the primary key
-- does not collide and nothing stops the duplicate seed.
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
VALUES (6, 2, CURRENT_DATE, 5);
COMMIT;
-- Now go back to A for [I4c-A5].


-- #####################################################################
-- I4-FIX -- THE SAME RACE, SERIALISED
-- #####################################################################

-- [I4FIX-B2] run immediately after A's [I4FIX-A1].
-- sp_register_team holds a FOR UPDATE lock on tournament 2, so this call
-- blocks until A commits. A locking read always sees the latest committed row
-- rather than the transaction's snapshot, so B's seed check then finds A's row.
-- ERROR 1644 "seed already taken in this tournament" is the PASS.
--
-- HONEST CAVEAT: this relies on the read view being established after the
-- locking read releases. If B unexpectedly SUCCEEDS, that is itself the
-- finding -- record it. FOR UPDATE narrows the window but does not close it in
-- every case, which is why UNIQUE (tournament_id, seed) is the primary fix and
-- the procedure check is defence in depth.
CALL sp_register_team(6, 2, 5);
-- Now go back to A for [I4FIX-A3].


-- #####################################################################
-- I5 -- WRITE SKEW ACROSS TABLES
-- #####################################################################

-- [I5-B2] run after A's [I5-A1]. B ends the membership A just validated.
START TRANSACTION;
UPDATE Membership SET left_date = CURRENT_DATE WHERE user_id = 10 AND org_id = 1;
COMMIT;
-- Now go back to A for [I5-A3]. A writes a StaffAssignments row on the
-- strength of a membership that no longer exists. Different tables, so InnoDB
-- has nothing to lock and nothing to detect.

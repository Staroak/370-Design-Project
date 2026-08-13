-- =====================================================================
-- 09_isolation_tests_a.sql    SESSION A     (pair: 09_isolation_tests_b.sql)

--
-- SETUP -- two terminals, both:
--     mysql -u root -p design_project_370
--     SET autocommit = 0;
--
-- Terminal 1 pastes the [X-A#] blocks from THIS file.
-- Terminal 2 pastes the [X-B#] blocks from 09_isolation_tests_b.sql.
-- Tests covered here:
--   A3  lock-wait timeout rolls back only the STATEMENT
--   A4  deadlock rolls back the WHOLE transaction  (contrast with A3)
--   I1  dirty read            (READ UNCOMMITTED)
--   I2  lost update
--   I3  read skew             (READ COMMITTED)
--   I4a write skew -- prize pool overdrawn
--   I4b write skew -- player active on two teams
--   I4c write skew -- duplicate seed
--   I4-FIX  the same race through sp_register_team, now serialised
--   I5  write skew -- staff booked for an org they just left
-- =====================================================================

USE design_project_370;
SET autocommit = 0;


-- #####################################################################
-- A3 -- LOCK-WAIT TIMEOUT ROLLS BACK ONLY THE FAILING STATEMENT
--
-- Session A just holds a lock. Session B does the interesting part: an INSERT
-- that succeeds, then an UPDATE that times out, then COMMIT. The INSERT still
-- commits, so B has written a payment without the pool change that justified
-- it. Atomicity here depends on B's error handling, not on START TRANSACTION.
-- #####################################################################

-- [A3-A1] then switch to B
START TRANSACTION;
UPDATE Tournament SET status = 'in_progress' WHERE tournament_id = 1;
-- holding the row lock on tournament 1. Do not commit.

-- [A3-A3] run after B reports ERROR 1205 and commits
ROLLBACK;
SELECT 'A3' AS test, status FROM Tournament WHERE tournament_id = 1;
COMMIT;


-- #####################################################################
-- A4 -- DEADLOCK ROLLS BACK THE ENTIRE TRANSACTION
--
-- Same two rows as A3, grabbed in opposite order. One session gets ERROR 1213
-- and loses everything -- the opposite scope from A3, from a failure that
-- looks the same to the client. Put these two side by side in the report.
-- #####################################################################

-- [A4-A1] then switch to B
START TRANSACTION;
UPDATE Tournament SET status = 'completed' WHERE tournament_id = 2;

-- [A4-A3] run after B's [A4-B2]. This blocks; one of the two sessions dies.
UPDATE Payments SET status = 'paid' WHERE payment_id = 3;

-- [A4-A4] whichever session survived, undo it
ROLLBACK;


-- #####################################################################
-- I1 -- DIRTY READ
--
-- A writes a large expense and never commits. B, at READ UNCOMMITTED, reports
-- a loss based on data that never existed.
-- #####################################################################

-- [I1-A1] then switch to B
START TRANSACTION;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, 1, 'expense', 'production', 50000.00, CURRENT_DATE);
SELECT 'I1-A' AS session, SUM(amount) AS expense_total
FROM Transactions WHERE tournament_id = 1 AND type = 'expense';

-- [I1-A3] run after B has read the phantom loss
ROLLBACK;
SELECT 'I1-A after rollback' AS session, SUM(amount) AS expense_total
FROM Transactions WHERE tournament_id = 1 AND type = 'expense';
COMMIT;


-- #####################################################################
-- I2 -- LOST UPDATE
--
-- Deliverable 5 starts at click_count = 3200. Two clicks are recorded, one
-- survives. This is the read-modify-write an application does when it computes
-- the new value in code instead of in SQL.
-- #####################################################################

-- [I2-A1] then switch to B
START TRANSACTION;
SELECT 'I2-A read' AS step, click_count FROM Deliverables WHERE deliverable_id = 5;

-- [I2-A3] run after B's [I2-B2]. A computed 3200 + 1 in application code.
UPDATE Deliverables SET click_count = 3201 WHERE deliverable_id = 5;
COMMIT;

-- [I2-A5] run last, after B commits
SELECT 'I2' AS test
     , click_count
     , IF(click_count = 3202, 'OK -- both clicks recorded'
        , 'GAP -- two clicks, one recorded (lost update)') AS verdict
FROM Deliverables WHERE deliverable_id = 5;
COMMIT;

-- [I2-A6] the fix: let the DBMS do the arithmetic. Reset first.
UPDATE Deliverables SET click_count = 3200 WHERE deliverable_id = 5;
COMMIT;
-- Now re-run I2 with this statement in both sessions instead. It cannot lose
-- an update, because the read and the write are one atomic statement:
--     UPDATE Deliverables SET click_count = click_count + 1 WHERE deliverable_id = 5;
-- SELECT ... FOR UPDATE before the read is the other fix, and is what
-- sp_pay_team_prize uses in 07_transactions.sql.


-- #####################################################################
-- I3 -- READ SKEW  (what REPEATABLE READ actually buys us)
--
-- B reads revenue, then expenses, in one transaction. A moves 1000 from one to
-- the other in between. Run this twice: at READ COMMITTED B reports the wrong
-- profit, at our REPEATABLE READ default it does not.
-- #####################################################################

-- [I3-A2] run after B's first SELECT in [I3-B1]
START TRANSACTION;
UPDATE Transactions SET amount = amount - 1000 WHERE transaction_id = 1;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, 1, 'expense', 'production', 1000.00, CURRENT_DATE);
COMMIT;

-- [I3-A5] reset, after B has reported both totals
DELETE FROM Transactions
WHERE tournament_id = 1 AND type = 'expense' AND category = 'production'
  AND amount = 1000.00 AND date = CURRENT_DATE;
UPDATE Transactions SET amount = 8000.00 WHERE transaction_id = 1;
COMMIT;


-- #####################################################################
-- I4a -- WRITE SKEW: PRIZE POOL OVERDRAWN
--
-- No setting is relaxed and no schema is changed. Both sessions run the same
-- individually-valid transaction at our default REPEATABLE READ, both pass the
-- headroom check, and the pool ends up overdrawn. This is the finding that
-- cannot be fixed with a CHECK constraint.
-- #####################################################################

-- [I4a-A1] create headroom: tournament 2 has a 3000 pool and 3000 already
-- paid out, so drop one payout to 1000 to leave exactly 1000 free.
UPDATE Payments SET amount = 1000.00 WHERE payment_id = 3;
COMMIT;
SELECT 'I4a setup' AS step
     , (SELECT prize_pool FROM Tournament WHERE tournament_id = 2)
     - COALESCE(SUM(amount), 0) AS headroom
FROM Payments WHERE tournament_id = 2 AND payee_type = 'team';

-- [I4a-A2] then switch to B. Both sessions see headroom = 1000.
START TRANSACTION;
SELECT (SELECT prize_pool FROM Tournament WHERE tournament_id = 2)
     - COALESCE(SUM(amount), 0) AS headroom_seen_by_A
FROM Payments WHERE tournament_id = 2 AND payee_type = 'team';

-- [I4a-A4] run after B's [I4a-B3]. 1000 <= 1000, so A proceeds.
INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('team', NULL, 1, 2, 1000.00, 'paid', CURRENT_DATE);
COMMIT;

-- [I4a-A6] run last, after B commits
SELECT 'I4a' AS test
     , (SELECT prize_pool FROM Tournament WHERE tournament_id = 2) AS prize_pool
     , SUM(amount) AS team_payouts
     , IF(SUM(amount) > (SELECT prize_pool FROM Tournament WHERE tournament_id = 2)
        , 'GAP -- two valid transactions overdrew the pool (not conflict-serialisable)'
        , 'OK') AS verdict
FROM Payments WHERE tournament_id = 2 AND payee_type = 'team';
COMMIT;

-- [I4a-A7] reset
DELETE FROM Payments
WHERE tournament_id = 2 AND payee_type = 'team' AND amount = 1000.00
  AND payment_date = CURRENT_DATE;
UPDATE Payments SET amount = 2000.00 WHERE payment_id = 3;
COMMIT;

-- [I4a-A8] the fix, for the report: sp_pay_team_prize in 07_transactions.sql
-- runs SELECT ... FROM Tournament ... FOR UPDATE before the headroom check, so
-- B queues behind A instead of reading a stale balance. Re-run I4a with both
-- sessions calling CALL sp_pay_team_prize(...) to show the second one refused.


-- #####################################################################
-- I4b -- WRITE SKEW: PLAYER ACTIVE ON TWO TEAMS
--
-- Player 47 has no Roster row at all, so both sessions correctly see zero
-- active teams. Then each adds a different one.
-- #####################################################################

-- [I4b-A1] then switch to B
START TRANSACTION;
SELECT COUNT(*) AS active_teams_seen_by_A
FROM Roster WHERE player_id = 47 AND leave_date IS NULL;

-- [I4b-A3] run after B's [I4b-B2]
INSERT INTO Roster (player_id, team_id, join_date, leave_date, salary, jersey_number)
VALUES (47, 5, CURRENT_DATE, NULL, 900.00, 10);
COMMIT;

-- [I4b-A5] run last, after B commits
SELECT 'I4b' AS test
     , COUNT(*) AS active_roster_rows
     , IF(COUNT(*) > 1, 'GAP -- player 47 is active on two teams at once', 'OK') AS verdict
FROM Roster WHERE player_id = 47 AND leave_date IS NULL;
COMMIT;

-- [I4b-A6] reset
DELETE FROM Roster WHERE player_id = 47;
COMMIT;


-- #####################################################################
-- I4c -- WRITE SKEW: DUPLICATE SEED FROM MAX(seed)+1
--
-- This is the pattern in the closing exercise of CSC370-19 (SELECT COUNT(*),
-- then a conditional INSERT), with our own table.
-- #####################################################################

-- [I4c-A1] then switch to B
START TRANSACTION;
SELECT COALESCE(MAX(seed), 0) + 1 AS next_seed_seen_by_A
FROM Registration WHERE tournament_id = 2;

-- [I4c-A3] run after B's [I4c-B2]. Both sessions computed 5.
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
VALUES (5, 2, CURRENT_DATE, 5);
COMMIT;

-- [I4c-A5] run last, after B commits
SELECT 'I4c' AS test
     , COUNT(*) AS competitors_on_seed_5
     , IF(COUNT(*) > 1, 'GAP -- two competitors share seed 5', 'OK') AS verdict
FROM Registration WHERE tournament_id = 2 AND seed = 5;
COMMIT;

-- [I4c-A6] reset
DELETE FROM Registration WHERE tournament_id = 2 AND competitor_id IN (5, 6);
COMMIT;


-- #####################################################################
-- I4-FIX -- THE SAME RACE, SERIALISED
--
-- Identical timing to I4c, but through sp_register_team. Its
-- SELECT ... FROM Tournament ... FOR UPDATE makes B block until A commits, so
-- B's seed check then sees A's row and refuses. ERROR 1644 in session B is the
-- PASS condition.
-- #####################################################################

-- [I4FIX-A1] then switch to B
CALL sp_register_team(5, 2, 5);

-- [I4FIX-A3] run last, after B reports ERROR 1644
SELECT 'I4-FIX' AS test
     , COUNT(*) AS competitors_on_seed_5
     , IF(COUNT(*) = 1, 'OK -- exactly one registration survived the race'
        , 'GAP -- the procedure did not serialise the race') AS verdict
FROM Registration WHERE tournament_id = 2 AND seed = 5;
COMMIT;

-- [I4FIX-A4] reset
DELETE FROM Registration WHERE tournament_id = 2 AND competitor_id IN (5, 6);
COMMIT;


-- #####################################################################
-- I5 -- WRITE SKEW ACROSS TABLES: STAFF BOOKED FOR AN ORG THEY JUST LEFT
--
-- A validates membership in Membership and writes to StaffAssignments; B
-- invalidates the membership. Different tables, so nothing collides, and the
-- invariant that spans them breaks.
-- #####################################################################

-- [I5-A1] then switch to B
START TRANSACTION;
SELECT COUNT(*) AS active_membership_seen_by_A
FROM Membership WHERE user_id = 10 AND org_id = 1 AND left_date IS NULL;

-- [I5-A3] run after B's [I5-B2]
INSERT INTO StaffAssignments (user_id, tournament_id, staff_role, pay_amount)
VALUES (10, 3, 'caster', 500.00);
COMMIT;

-- [I5-A5] run last, after B commits
SELECT 'I5' AS test
     , IF(COUNT(*) > 0, 'GAP -- caster booked for an org they no longer belong to', 'OK') AS verdict
FROM StaffAssignments sa
JOIN Tournament t  ON t.tournament_id = sa.tournament_id
LEFT JOIN Membership mb
       ON mb.user_id = sa.user_id AND mb.org_id = t.org_id AND mb.left_date IS NULL
WHERE sa.user_id = 10 AND sa.tournament_id = 3 AND mb.user_id IS NULL;
COMMIT;

-- [I5-A6] reset
DELETE FROM StaffAssignments WHERE user_id = 10 AND tournament_id = 3;
UPDATE Membership SET left_date = NULL WHERE user_id = 10 AND org_id = 1;
COMMIT;


-- =====================================================================
-- Final state check -- must match 02_insert_data.sql exactly.
-- =====================================================================
SELECT 'I-RESIDUE' AS test
     , (SELECT click_count FROM Deliverables WHERE deliverable_id = 5)          AS clicks_should_be_3200
     , (SELECT amount FROM Transactions WHERE transaction_id = 1)               AS revenue_should_be_8000
     , (SELECT amount FROM Payments WHERE payment_id = 3)                       AS payment_should_be_2000
     , (SELECT COUNT(*) FROM Roster WHERE player_id = 47)                       AS roster_should_be_0
     , (SELECT COUNT(*) FROM Registration WHERE tournament_id = 2 AND seed = 5) AS seed5_should_be_0
     , (SELECT COUNT(*) FROM StaffAssignments
        WHERE user_id = 10 AND tournament_id = 3)                               AS staff_should_be_0
     , (SELECT COUNT(*) FROM Membership
        WHERE user_id = 10 AND org_id = 1 AND left_date IS NOT NULL)            AS left_date_should_be_0;
COMMIT;

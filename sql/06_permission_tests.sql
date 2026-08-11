-- =====================================================================
-- 06_permission_tests.sql    evidence that the grants actually bind
--
-- This file is NOT run as root. Each block runs as a different account, so
-- replay it with the command shown above each section. The captured results are
-- in permission_test_output.txt, produced by:
--     bash run_permission_tests.sh
--
-- Password for every demo account: Csc370demo!
-- =====================================================================


-- =====================================================================
-- TEST 1 -- AUDIENCE
-- mysql -u audience_guest -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: public standings, including the TFT lobby and the 1v1
SELECT tournament, standing, competitor, competitor_type, total_points
FROM v_public_standings WHERE tournament_id = 3 ORDER BY standing;

-- ALLOW: rosters, without salary -- the column does not exist in this view
SELECT team_name, ign, jersey_number FROM v_public_rosters LIMIT 5;

-- DENY (ERROR 1142): the base table behind that view. Salary is unreachable.
SELECT player_id, team_id, salary FROM Roster LIMIT 5;

-- DENY (ERROR 1142): credentials. This is the SQL-injection scenario -- if the
-- public connection held table privileges, a concatenated ORDER BY could dump
-- every password. The grant makes the vulnerability unexploitable.
SELECT email, password FROM Users LIMIT 5;

-- DENY (ERROR 1142): money
SELECT * FROM Transactions LIMIT 5;

-- DENY (ERROR 1142): an admin view exists but is not granted to this role
SELECT * FROM v_org_financials;


-- =====================================================================
-- TEST 2 -- PLAYER  (row-level security)
-- mysql -u player_aus -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: inherited from role_audience through the role hierarchy
SELECT COUNT(*) AS visible_public_rows FROM v_public_standings;

-- ALLOW: own profile WITH salary. Same Roster table as v_public_rosters above,
-- different columns, different role. The filter is inside the view.
SELECT ign, team_name, jersey_number, salary FROM v_my_profile;

-- ALLOW: own match history only
SELECT tournament, match_id, kills, deaths, assists FROM v_my_match_history LIMIT 5;

-- DENY (ERROR 1142): no privilege on Roster, so the view cannot be bypassed
-- to read another player's salary.
SELECT player_id, salary FROM Roster ORDER BY salary DESC LIMIT 5;

-- DENY (ERROR 1142): staff operations are not on the player branch
SELECT * FROM v_tournament_ops LIMIT 3;


-- =====================================================================
-- TEST 3 -- ESPORTS ORG  (tenant isolation, lateral branch)
-- mysql -u org_qor -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: own teams' payouts only. QOR sees QOR.
SELECT esports_org, team_name, tournament, amount, status FROM v_my_team_payouts;

-- DENY (ERROR 1142): all payouts for everyone
SELECT * FROM Payments LIMIT 5;

-- DENY (ERROR 1142): a player's personal profile is not on this branch
SELECT * FROM v_my_profile;


-- =====================================================================
-- TEST 4 -- STAFF
-- mysql -u staff_caster -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: who is playing, casting and streaming
SELECT tournament, match_id, competitors, staff_on_match FROM v_tournament_ops LIMIT 5;

-- ALLOW: deliverables to chase -- note there is no total_value column here
SELECT party, description, due_date, status FROM v_deliverable_status LIMIT 5;

-- ALLOW: the APP/TRIGGER constraints as detectable reports. Empty = data clean.
SELECT * FROM v_registration_violations;
SELECT match_id, tournament, participant_count, issue FROM v_match_integrity
WHERE issue <> 'ok';

-- ALLOW: staff may mark a deliverable fulfilled (column-level UPDATE grant)
UPDATE Deliverables SET status = 'fulfilled' WHERE deliverable_id = 4;

-- DENY (ERROR 1143): column-level grant covers `status` ONLY. Staff cannot
-- move a deadline or repoint a deliverable at another contract.
UPDATE Deliverables SET due_date = '2027-01-01' WHERE deliverable_id = 4;

-- DENY (ERROR 1142): contract values are above the staff tier
SELECT contract_id, total_value FROM Contracts LIMIT 5;

-- DENY (ERROR 1142): org finances are admin-only
SELECT * FROM v_org_financials;

-- DENY (ERROR 1142): payroll
SELECT * FROM v_outstanding_payments;


-- =====================================================================
-- TEST 5 -- ADMIN  (row-level security on money)
-- mysql -u admin_mtb -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: own org's profitability. The view resolved CURRENT_USER() to
-- Users.db_username = 'admin_mtb' and confirmed an active 'admin' Membership.
SELECT * FROM v_org_financials;

-- ALLOW: who is still owed money, own org
SELECT payee_type, payee, tournament, amount, status FROM v_outstanding_payments;

-- ALLOW: staff roster of the org -- email yes, password never
SELECT org_name, full_name, email, role FROM v_org_membership;

-- ALLOW: inherited from role_staff
SELECT COUNT(*) AS ops_rows FROM v_tournament_ops;

-- DENY (ERROR 1142): even an org admin has no direct table access. All money
-- reads go through the org-filtered views, so cross-tenant reads are
-- impossible rather than merely discouraged.
SELECT * FROM Transactions LIMIT 5;

-- DENY (ERROR 1142): password hashes are not reachable at any tier
SELECT email, password FROM Users LIMIT 5;

-- DENY (ERROR 1142): no DDL
DROP TABLE Payments;


-- =====================================================================
-- TEST 6 -- SPONSOR  (lateral branch, own contract only)
-- mysql -u sponsor_redbull -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: Red Bull's own contract and deliverable fulfilment, self-serve
SELECT company_name, tournament, total_value, description, status, click_count
FROM v_my_contract_deliverables;

-- DENY (ERROR 1142): every sponsor's contract
SELECT * FROM Contracts LIMIT 5;

-- DENY (ERROR 1142): the organizer's profit on the event they sponsored
SELECT * FROM v_org_financials;

-- DENY (ERROR 1142): staff-tier deliverable tracking across all sponsors
SELECT * FROM v_deliverable_status LIMIT 5;


-- =====================================================================
-- TEST 7 -- CREATOR  (lateral branch)
-- mysql -u creator_revrzd -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: own rate, own assignments, own stream count
SELECT tournament, role, rate, status, matches_streamed FROM v_my_creator_assignments;

-- DENY (ERROR 1142): other creators' rates
SELECT * FROM CreatorAssignment LIMIT 5;


-- =====================================================================
-- TEST 8 -- DBA
-- mysql -u dba_370 -pCsc370demo! design_project_370
-- =====================================================================

-- ALLOW: base tables, because this is the only principal that owns the schema
SELECT COUNT(*) AS transaction_rows FROM Transactions;
SELECT COUNT(*) AS user_rows FROM Users;


-- =====================================================================
-- TEST 9 -- THE GRANT CATALOGUE
-- mysql -u root -p design_project_370
-- =====================================================================

SHOW GRANTS FOR 'role_audience';
SHOW GRANTS FOR 'role_staff';
SHOW GRANTS FOR 'admin_mtb'@'localhost' USING 'role_admin';

SELECT FROM_USER, TO_USER FROM mysql.role_edges ORDER BY TO_USER, FROM_USER;


-- =====================================================================
-- TEST 10 -- NEGATIVE CONTROL for the data-quality views
-- mysql -u root -p design_project_370
--
-- In TEST 4 both v_registration_violations and v_match_integrity returned
-- nothing. Empty is the correct answer for clean data, but on its own it is
-- indistinguishable from a view that is silently broken. So: deliberately
-- insert the two violations, confirm each view catches them, then ROLLBACK so
-- the database is left exactly as it was.
--
-- This is also the argument for these views existing at all. Both rules are
-- marked APP/TRIGGER in 01_create_tables.sql because they span rows or tables
-- and cannot be CHECK constraints -- note that both bad rows below INSERT
-- successfully. The database cannot refuse them; the views can find them.
-- =====================================================================

START TRANSACTION;

-- Violation 1: register a Valorant team (competitor 1, game 1) into the
-- Teamfight Tactics tournament (tournament 3, game 2).
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
VALUES (1, 3, '2026-04-20', 9);

-- Violation 2: a third competitor in an elimination match, sharing a placement
-- with an existing row (match 1 already has placements 1 and 2).
INSERT INTO MatchParticipant (match_id, competitor_id, placement, points)
VALUES (1, 3, 2, 0);

-- Both views should now be non-empty. THESE RESULTS ARE THE EVIDENCE.
SELECT * FROM v_registration_violations;

SELECT match_id, tournament, format, participant_count, distinct_placements, issue
FROM v_match_integrity WHERE issue <> 'ok';

ROLLBACK;

-- Back to clean: both should be empty again.
SELECT COUNT(*) AS registration_violations_after_rollback FROM v_registration_violations;
SELECT COUNT(*) AS match_issues_after_rollback FROM v_match_integrity WHERE issue <> 'ok';

-- =====================================================================
-- 05_roles_and_grants.sql   -- DBMS-enforced access control
--
-- Run order: 01_create_tables -> 02_insert_data -> 04_views -> 05_roles_and_grants
-- Requires MySQL 8.0+ (CREATE ROLE did not exist in 5.7). Tested on 8.0.46.
--
-- WHY THIS EXISTS, GIVEN WE ALREADY HAVE Membership.role
-- Those are two different things and both are needed:
--   Membership.role is DATA. It says which human holds which job, and the
--     application reads it to decide what to offer in the UI. It expresses
--     business rules the database cannot ("a caster may edit a score only
--     while the match is live"). It is enforced only on the code path we wrote.
--   The roles below are CATALOG METADATA. They are checked by the server on
--     every statement it receives, including statements our application never
--     produced: a SQL injection payload, a teammate in Workbench, a cron job,
--     a mysqldump. An application check cannot stop a query it never saw.
-- Application roles decide what is offered. Database roles decide what is
-- possible. See 06_permission_tests.sql -- the DENIALS are the evidence: a
-- query that succeeds only proves a grant is wide enough, never that it is
-- tight enough.
--
-- WHERE ACCESS CONTROL IS STORED
-- Not in a table of ours. MySQL persists all of this itself in the `mysql`
-- system database (mysql.user, mysql.role_edges, mysql.tables_priv,
-- mysql.columns_priv). This file is the versioned source of truth for the
-- statements that produce it, and `SHOW GRANTS` reads it back.
--
-- DEMO CREDENTIALS: the passwords below are throwaway localhost values for
-- marking this project. Do not reuse them anywhere.
-- =====================================================================

USE design_project_370;


-- =====================================================================
-- 1. ROLES
--
-- The README described a single "most to least" chain. It is actually a
-- lattice, because sponsors and creators are not rungs on the staff ladder --
-- a sponsor must see more than the audience about its own contract while
-- seeing nothing about rosters or payroll.
--
--                       role_dba          (owns the schema; DDL)
--
--                      role_admin         (org's own money)
--                          |
--                      role_staff         (event operations)
--                          |
--     role_player   role_esports_org   role_sponsor   role_creator
--            \            |                 |            /
--             ----------  role_audience  ----------
--
-- role_admin is a TENANT admin, not a database administrator. role_dba is a
-- separate principal; keeping them apart is the point of having both.
-- =====================================================================

CREATE ROLE IF NOT EXISTS
    'role_audience'
  , 'role_player'
  , 'role_esports_org'
  , 'role_staff'
  , 'role_admin'
  , 'role_sponsor'
  , 'role_creator'
  , 'role_dba';


-- =====================================================================
-- 2. PRIVILEGES ON VIEWS, NOT BASE TABLES
--
-- Nothing below role_dba is granted anything on Users, Roster, Contracts,
-- Transactions, Payments or Membership. Every read goes through a view, so the
-- view controls which columns and which rows are reachable. Because views are
-- SQL SECURITY DEFINER, these accounts can read through them while holding
-- zero privileges on the tables underneath.
-- =====================================================================

-- --- audience: the floor ---------------------------------------------
GRANT SELECT ON design_project_370.v_public_schedule     TO 'role_audience';
GRANT SELECT ON design_project_370.v_public_standings    TO 'role_audience';
GRANT SELECT ON design_project_370.v_public_rosters      TO 'role_audience';
GRANT SELECT ON design_project_370.v_public_player_stats TO 'role_audience';

-- --- player: own profile incl. salary, own match history --------------
GRANT SELECT ON design_project_370.v_my_profile       TO 'role_player';
GRANT SELECT ON design_project_370.v_my_match_history TO 'role_player';

-- --- esports org: own teams' prize payouts ---------------------------
GRANT SELECT ON design_project_370.v_my_team_payouts TO 'role_esports_org';

-- --- staff: event operations -----------------------------------------
GRANT SELECT ON design_project_370.v_tournament_ops          TO 'role_staff';
GRANT SELECT ON design_project_370.v_deliverable_status      TO 'role_staff';
GRANT SELECT ON design_project_370.v_registration_violations TO 'role_staff';
GRANT SELECT ON design_project_370.v_match_integrity         TO 'role_staff';

-- WRITE ACCESS IS A SEPARATE PROBLEM.
-- A view over joins is not updatable in MySQL, so read-security via views buys
-- us nothing for writes. Those need direct grants on base tables -- and note
-- the column-level grant on Deliverables: staff may mark a deliverable
-- fulfilled but cannot touch due_date, contract_id or description.
GRANT INSERT, UPDATE ON design_project_370.MatchParticipant TO 'role_staff';
GRANT INSERT          ON design_project_370.Registration    TO 'role_staff';

-- The SELECT (deliverable_id) half is not redundant: a column-level UPDATE
-- grant does NOT imply the read privilege needed to evaluate the statement's
-- own WHERE clause. Without it, "UPDATE Deliverables SET status=... WHERE
-- deliverable_id = 4" fails with ERROR 1143 on deliverable_id -- which looks
-- like the update itself was denied when it was really the lookup.
GRANT SELECT (deliverable_id), UPDATE (status)
    ON design_project_370.Deliverables TO 'role_staff';

-- --- admin: own org's finances ---------------------------------------
GRANT SELECT ON design_project_370.v_org_financials      TO 'role_admin';
GRANT SELECT ON design_project_370.v_outstanding_payments TO 'role_admin';
GRANT SELECT ON design_project_370.v_org_membership       TO 'role_admin';

-- --- lateral tiers ----------------------------------------------------
GRANT SELECT ON design_project_370.v_my_contract_deliverables TO 'role_sponsor';
GRANT SELECT ON design_project_370.v_my_creator_assignments   TO 'role_creator';

-- --- dba: the only principal with the base tables and DDL ------------
GRANT ALL PRIVILEGES ON design_project_370.* TO 'role_dba';


-- =====================================================================
-- 3. ROLE HIERARCHY
--
-- Roles can be granted to roles, which gives the "most to least" hierarchy for
-- free. Note that role_player is NOT granted to role_esports_org or role_staff:
-- an org rep or a caster has no business reading a player's salary.
--
-- Inheriting from role_audience is safe even for principals that own no rows,
-- because the v_my_* views filter on CURRENT_USER(). A role that owns no rows
-- in a view inherits an empty result set, not a leak -- row-filtered views make
-- generous inheritance harmless.
-- =====================================================================

GRANT 'role_audience' TO 'role_player';
GRANT 'role_audience' TO 'role_esports_org';
GRANT 'role_audience' TO 'role_staff';
GRANT 'role_audience' TO 'role_sponsor';
GRANT 'role_audience' TO 'role_creator';
GRANT 'role_staff'    TO 'role_admin';


-- =====================================================================
-- 4. NAMED PRINCIPALS (one per role, for the marking demo)
--
-- These names must match the db_username values set at the end of
-- 02_insert_data.sql -- that mapping is what makes the v_my_* row filtering
-- resolve to a person.
-- =====================================================================

CREATE USER IF NOT EXISTS 'audience_guest'@'localhost'  IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'player_aus'@'localhost'      IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'org_qor'@'localhost'         IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'staff_caster'@'localhost'    IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'admin_mtb'@'localhost'       IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'sponsor_redbull'@'localhost' IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'creator_revrzd'@'localhost'  IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'dba_370'@'localhost'         IDENTIFIED BY 'Csc370demo!';

GRANT 'role_audience'    TO 'audience_guest'@'localhost';
GRANT 'role_player'      TO 'player_aus'@'localhost';
GRANT 'role_esports_org' TO 'org_qor'@'localhost';
GRANT 'role_staff'       TO 'staff_caster'@'localhost';
GRANT 'role_admin'       TO 'admin_mtb'@'localhost';
GRANT 'role_sponsor'     TO 'sponsor_redbull'@'localhost';
GRANT 'role_creator'     TO 'creator_revrzd'@'localhost';
GRANT 'role_dba'         TO 'dba_370'@'localhost';


-- =====================================================================
-- 5. ACTIVATE THE ROLES  <-- do not skip this
--
-- A granted role is INACTIVE by default in MySQL 8 (@@activate_all_roles_on_login
-- is 0 on this server). Without the statements below, every account gets
-- ERROR 1142 on everything even though SHOW GRANTS lists the role correctly.
-- This is the single most common reason a grants demo appears not to work.
-- =====================================================================

SET DEFAULT ROLE ALL TO
    'audience_guest'@'localhost'
  , 'player_aus'@'localhost'
  , 'org_qor'@'localhost'
  , 'staff_caster'@'localhost'
  , 'admin_mtb'@'localhost'
  , 'sponsor_redbull'@'localhost'
  , 'creator_revrzd'@'localhost'
  , 'dba_370'@'localhost';

FLUSH PRIVILEGES;


-- =====================================================================
-- 6. WHAT PRODUCTION WOULD ACTUALLY DO
--
-- One MySQL account per human does not survive connection pooling, and would
-- be absurd for an audience of 100k. The realistic pattern is a handful of
-- TIER accounts, chosen by the application from the user's Membership.role:
--
--     app_public -> role_audience   (unauthenticated traffic)
--     app_user   -> role_player     (logged in)
--     app_admin  -> role_admin      (admin endpoints only)
--
-- Membership.role picks the connection pool; the grants cap what that pool
-- could ever reach. Both layers, no per-user accounts. An injection on a public
-- endpoint is confined to what role_audience can read.
--
-- The honest limitation: tier accounts break the v_my_* views, because
-- CURRENT_USER() is then 'app_user', not a person. Real systems pass identity
-- in a session variable and the view filters on that instead. MySQL has no
-- CREATE POLICY, so unlike PostgreSQL there is no first-class way to do this --
-- worth stating plainly rather than pretending the view approach scales as-is.
-- The tier accounts are created here to show the structure; the demo in 06 uses
-- the named accounts above because row-level filtering needs a real identity.
-- =====================================================================

CREATE USER IF NOT EXISTS 'app_public'@'localhost' IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'app_user'@'localhost'   IDENTIFIED BY 'Csc370demo!';
CREATE USER IF NOT EXISTS 'app_admin'@'localhost'  IDENTIFIED BY 'Csc370demo!';

GRANT 'role_audience' TO 'app_public'@'localhost';
GRANT 'role_player'   TO 'app_user'@'localhost';
GRANT 'role_admin'    TO 'app_admin'@'localhost';

SET DEFAULT ROLE ALL TO
    'app_public'@'localhost'
  , 'app_user'@'localhost'
  , 'app_admin'@'localhost';

FLUSH PRIVILEGES;

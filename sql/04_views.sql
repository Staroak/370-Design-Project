-- =====================================================================
-- 04_views.sql   -- the permission surface
--
-- Run order: 01_create_tables -> 02_insert_data -> 04_views -> 05_roles_and_grants
--
-- WHY VIEWS AND NOT TABLE GRANTS
-- A view is the security boundary. Two things it does that GRANT on a base
-- table cannot:
--   1. Column hiding. v_public_rosters and v_my_profile read the SAME Roster
--      table, but only one of them has a salary column. Nobody below
--      role_player is granted anything on Roster itself.
--   2. Row filtering (row-level security). MySQL has no CREATE POLICY, so the
--      v_my_* views hand-roll it by joining our db_username column against the
--      connected account name. Two admins from different orgs run the identical
--      query and get different rows. This is what backs the "one shared
--      database, isolated per organization" requirement: isolation lives inside
--      the view and cannot be forgotten the way an application WHERE clause can.
--
-- Views default to SQL SECURITY DEFINER, so they execute with the definer's
-- privileges. That is the whole trick: an account can read THROUGH a view while
-- holding zero privileges on the base tables underneath it.
--
-- WHY SESSION_USER() AND NOT CURRENT_USER()  <-- non-obvious, cost us a bug
-- Inside a DEFINER view these are NOT the same. CURRENT_USER() returns the
-- account whose privileges are in force, which for a DEFINER view is the
-- DEFINER (root), not the caller -- so every v_my_* filter silently matched
-- nothing and returned an empty set with no error. SESSION_USER() (a synonym
-- for USER()) returns the account that actually connected, which is the one we
-- want. Verified on this server:
--     as player_aus:  CURRENT_USER() = root@localhost
--                     SESSION_USER() = player_aus@localhost
-- A filter that fails open would be a security bug; this one failed closed, but
-- it is the same mistake and worth stating.
-- =====================================================================

USE design_project_370;


-- =====================================================================
-- AUDIENCE TIER -- the floor. No money, no contact details, no salaries.
-- =====================================================================

-- Tournament listings. prize_pool is included because it is advertised
-- publicly; Organization.contact_email is deliberately left out.
CREATE OR REPLACE VIEW v_public_schedule AS
SELECT
    t.tournament_id
  , t.name       AS tournament
  , g.title      AS game
  , o.org_name   AS organizer
  , t.start_date
  , t.end_date
  , t.format
  , t.status
  , t.prize_pool
FROM Tournament t
JOIN Game g         ON g.game_id = t.game_id
JOIN Organization o ON o.org_id  = t.org_id;


-- Final standings for every tournament regardless of format or competitor
-- count (wraps Q13). Works for the 8-team Valorant bracket, the 8-player TFT
-- lobby series and the 1v1 alike, because results are rows in
-- MatchParticipant rather than team1_id/team2_id columns.
CREATE OR REPLACE VIEW v_public_standings AS
SELECT
    t.tournament_id
  , t.name   AS tournament
  , t.format
  , RANK() OVER (PARTITION BY t.tournament_id
                 ORDER BY SUM(mp.points) DESC, MIN(mp.placement) ASC) AS standing
  , COALESCE(tm.team_name, pl.ign) AS competitor
  , c.competitor_type
  , COUNT(*)          AS matches_played
  , SUM(mp.points)    AS total_points
  , MIN(mp.placement) AS best_placement
FROM MatchParticipant mp
JOIN `Match` m       ON m.match_id      = mp.match_id
JOIN Tournament t    ON t.tournament_id = m.tournament_id
JOIN Competitor c    ON c.competitor_id = mp.competitor_id
LEFT JOIN Teams tm   ON tm.team_id   = c.team_id
LEFT JOIN Players pl ON pl.player_id = c.player_id
GROUP BY t.tournament_id, t.name, t.format
       , c.competitor_id, c.competitor_type, tm.team_name, pl.ign;


-- Active rosters. COLUMN-HIDING DEMO: Roster.salary exists in the base table
-- and is absent here. Compare with v_my_profile, which reads the same table.
CREATE OR REPLACE VIEW v_public_rosters AS
SELECT
    tm.team_name
  , g.title AS game
  , pl.ign
  , r.jersey_number
FROM Roster r
JOIN Teams tm   ON tm.team_id   = r.team_id
JOIN Players pl ON pl.player_id = r.player_id
JOIN Game g     ON g.game_id    = tm.game_id
WHERE r.leave_date IS NULL;


-- Aggregate player performance per game (wraps Q6/Q9).
CREATE OR REPLACE VIEW v_public_player_stats AS
SELECT
    pl.player_id
  , pl.ign
  , g.title AS game
  , COUNT(DISTINCT pms.match_id) AS matches_played
  , SUM(pms.kills)   AS total_kills
  , SUM(pms.deaths)  AS total_deaths
  , SUM(pms.assists) AS total_assists
  , ROUND(SUM(pms.kills) / NULLIF(SUM(pms.deaths), 0), 2) AS kd_ratio
FROM PlayerMatchStats pms
JOIN Players pl   ON pl.player_id     = pms.player_id
JOIN `Match` m    ON m.match_id       = pms.match_id
JOIN Tournament t ON t.tournament_id  = m.tournament_id
JOIN Game g       ON g.game_id        = t.game_id
GROUP BY pl.player_id, pl.ign, g.game_id, g.title;


-- =====================================================================
-- PLAYER TIER -- own data only, enforced by the view not by the caller.
-- =====================================================================

-- Same Roster table as v_public_rosters, but WITH salary, and restricted to
-- the calling player's own rows. A player cannot widen this: the filter is
-- inside the view, and they have no privilege on Roster to go around it.
CREATE OR REPLACE VIEW v_my_profile AS
SELECT
    pl.player_id
  , pl.ign
  , pl.real_name
  , pl.country
  , tm.team_name
  , r.jersey_number
  , r.join_date
  , r.leave_date
  , r.salary
FROM Players pl
JOIN Roster r ON r.player_id = pl.player_id
JOIN Teams tm ON tm.team_id  = r.team_id
WHERE pl.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);


CREATE OR REPLACE VIEW v_my_match_history AS
SELECT
    t.name AS tournament
  , m.match_id
  , m.scheduled_time
  , pms.kills
  , pms.deaths
  , pms.assists
  , pms.score
FROM PlayerMatchStats pms
JOIN Players pl   ON pl.player_id    = pms.player_id
JOIN `Match` m    ON m.match_id      = pms.match_id
JOIN Tournament t ON t.tournament_id = m.tournament_id
WHERE pl.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);


-- =====================================================================
-- ESPORTS ORG TIER -- a parent org (TSM, QOR) sees only its own teams.
-- =====================================================================

CREATE OR REPLACE VIEW v_my_team_payouts AS
SELECT
    eo.name   AS esports_org
  , tm.team_name
  , t.name    AS tournament
  , p.amount
  , p.status
  , p.payment_date
FROM EsportsOrg eo
JOIN Teams tm     ON tm.esports_org_id = eo.esports_org_id
JOIN Payments p   ON p.team_id = tm.team_id AND p.payee_type = 'team'
JOIN Tournament t ON t.tournament_id = p.tournament_id
WHERE eo.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);


-- =====================================================================
-- STAFF TIER -- run the event. Ops detail, but no contract values, no
-- payroll, no org finances.
-- =====================================================================

-- Who is playing, casting and streaming each match.
CREATE OR REPLACE VIEW v_tournament_ops AS
SELECT
    t.name AS tournament
  , m.match_id
  , m.scheduled_time
  , (SELECT GROUP_CONCAT(COALESCE(tm2.team_name, pl2.ign)
                         ORDER BY mp2.placement SEPARATOR ' vs ')
     FROM MatchParticipant mp2
     JOIN Competitor c2    ON c2.competitor_id = mp2.competitor_id
     LEFT JOIN Teams tm2   ON tm2.team_id   = c2.team_id
     LEFT JOIN Players pl2 ON pl2.player_id = c2.player_id
     WHERE mp2.match_id = m.match_id)                       AS competitors
  , (SELECT GROUP_CONCAT(CONCAT(u.full_name, ' (', sm.role, ')') SEPARATOR ', ')
     FROM StaffMatches sm
     JOIN Users u ON u.user_id = sm.user_id
     WHERE sm.match_id = m.match_id)                        AS staff_on_match
  , (SELECT COUNT(*) FROM CreatorMatches cm
     WHERE cm.match_id = m.match_id)                        AS creators_streaming
FROM `Match` m
JOIN Tournament t ON t.tournament_id = m.tournament_id;


-- Deliverable tracking for staff who chase sponsors. Contracts.total_value is
-- deliberately excluded: staff need to know WHAT is owed, not what it cost.
CREATE OR REPLACE VIEW v_deliverable_status AS
SELECT
    d.deliverable_id
  , COALESCE(s.company_name, CONCAT('creator #', cr.creator_id)) AS party
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


-- DATA-QUALITY VIEWS
-- 01_create_tables.sql marks several rules APP/TRIGGER because they span rows
-- or tables and cannot be written as CHECK constraints. A view cannot enforce
-- them either -- but it can make them DETECTABLE, which turns an unenforceable
-- constraint into an operational report. An empty result means the data is clean.

-- The "team and tournament must be for the same game" rule from Registration.
CREATE OR REPLACE VIEW v_registration_violations AS
SELECT
    r.tournament_id
  , t.name     AS tournament
  , g_t.title  AS tournament_game
  , tm.team_name
  , g_tm.title AS team_game
FROM Registration r
JOIN Tournament t ON t.tournament_id = r.tournament_id
JOIN Game g_t     ON g_t.game_id     = t.game_id
JOIN Competitor c ON c.competitor_id = r.competitor_id
JOIN Teams tm     ON tm.team_id      = c.team_id
JOIN Game g_tm    ON g_tm.game_id    = tm.game_id
WHERE c.competitor_type = 'team'
  AND tm.game_id <> t.game_id;


-- Results sanity: an elimination match must have exactly 2 competitors, and no
-- two competitors in one match may share a placement.
CREATE OR REPLACE VIEW v_match_integrity AS
SELECT
    m.match_id
  , t.name   AS tournament
  , t.format
  , COUNT(mp.competitor_id)        AS participant_count
  , COUNT(DISTINCT mp.placement)   AS distinct_placements
  , CASE
        WHEN COUNT(mp.competitor_id) = 0
            THEN 'no participants recorded'
        WHEN t.format = 'Single Elimination' AND COUNT(mp.competitor_id) <> 2
            THEN 'elimination match without exactly 2 competitors'
        WHEN COUNT(DISTINCT mp.placement) <> COUNT(mp.competitor_id)
            THEN 'duplicate placement within one match'
        ELSE 'ok'
    END AS issue
FROM `Match` m
JOIN Tournament t             ON t.tournament_id = m.tournament_id
LEFT JOIN MatchParticipant mp ON mp.match_id     = m.match_id
GROUP BY m.match_id, t.name, t.format;


-- =====================================================================
-- ADMIN TIER -- money, but only for the caller's own organization.
-- =====================================================================

-- ROW-LEVEL SECURITY DEMO (wraps Q1). Two admins from different orgs run
-- SELECT * FROM v_org_financials and get different rows, because the view
-- joins Membership against CURRENT_USER(). Also requires the caller to
-- currently hold the 'admin' role in that org (left_date IS NULL).
CREATE OR REPLACE VIEW v_org_financials AS
SELECT
    t.tournament_id
  , t.name AS tournament
  , SUM(CASE WHEN tr.type = 'revenue' THEN tr.amount ELSE 0 END)      AS total_revenue
  , SUM(CASE WHEN tr.type = 'expense' THEN tr.amount ELSE 0 END)      AS total_expense
  , SUM(CASE WHEN tr.type = 'revenue' THEN tr.amount ELSE -tr.amount END) AS profit
FROM Transactions tr
JOIN Tournament t  ON t.tournament_id = tr.tournament_id
JOIN Membership mb ON mb.org_id       = tr.org_id
JOIN Users u       ON u.user_id       = mb.user_id
WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
  AND mb.role = 'admin'
  AND mb.left_date IS NULL
GROUP BY t.tournament_id, t.name;


-- Who is still owed money, own org only (wraps Q8).
CREATE OR REPLACE VIEW v_outstanding_payments AS
SELECT
    p.payment_id
  , p.payee_type
  , COALESCE(u_payee.full_name, tm.team_name) AS payee
  , t.name AS tournament
  , p.amount
  , p.status
FROM Payments p
JOIN Tournament t        ON t.tournament_id = p.tournament_id
LEFT JOIN Users u_payee  ON u_payee.user_id = p.staff_user_id
LEFT JOIN Teams tm       ON tm.team_id      = p.team_id
JOIN Membership mb       ON mb.org_id       = t.org_id
JOIN Users u             ON u.user_id       = mb.user_id
WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
  AND mb.role = 'admin'
  AND mb.left_date IS NULL
  AND p.status <> 'paid';


-- Org roster of staff. Users.password is NEVER exposed, at any level.
CREATE OR REPLACE VIEW v_org_membership AS
SELECT
    o.org_name
  , u_member.user_id
  , u_member.full_name
  , u_member.email
  , mb.role
  , mb.joined_date
  , mb.left_date
FROM Membership mb
JOIN Users u_member     ON u_member.user_id = mb.user_id
JOIN Organization o     ON o.org_id         = mb.org_id
JOIN Membership mb_self ON mb_self.org_id   = mb.org_id
JOIN Users u            ON u.user_id        = mb_self.user_id
WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
  AND mb_self.role = 'admin'
  AND mb_self.left_date IS NULL;


-- =====================================================================
-- LATERAL TIERS -- sponsors and creators are not rungs on the staff ladder.
-- They see more than the audience about THEIR OWN agreement and nothing else.
-- =====================================================================

-- Self-serve version of Q11. A sponsor sees their own contract value (it is
-- their money) but nothing about rosters, payroll or org profit.
CREATE OR REPLACE VIEW v_my_contract_deliverables AS
SELECT
    s.company_name
  , t.name AS tournament
  , c.contract_id
  , c.total_value
  , d.description
  , d.type
  , d.due_date
  , d.status
  , d.click_count
FROM Sponsors s
JOIN Contracts c        ON c.sponsor_id   = s.sponsor_id AND c.party_type = 'sponsor'
LEFT JOIN Deliverables d ON d.contract_id = c.contract_id
LEFT JOIN Tournament t   ON t.tournament_id = c.tournament_id
WHERE s.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);


CREATE OR REPLACE VIEW v_my_creator_assignments AS
SELECT
    t.name AS tournament
  , ca.role
  , ca.rate
  , ca.status
  , (SELECT COUNT(*) FROM CreatorMatches cm WHERE cm.creator_id = cr.creator_id) AS matches_streamed
FROM Creators cr
JOIN CreatorAssignment ca ON ca.creator_id    = cr.creator_id
JOIN Tournament t         ON t.tournament_id  = ca.tournament_id
WHERE cr.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);

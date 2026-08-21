
USE design_project_370;


-- #####################################################################
-- #  P A R T   A   --   the six corrected views
-- #####################################################################

-- =====================================================================
-- FIX 1 (test N1) -- v_org_financials
--
-- Transactions.tournament_id is NULLABLE by design: an org-level transaction
-- (rent, a yearly licence, a blanket sponsorship) belongs to no tournament.
-- The old inner join deleted that money from the profit report. LEFT JOIN keeps
-- it and it lands in its own group, labelled, instead of disappearing.
--
-- The WHERE clause touches only tr, mb and u -- never t -- so rule 2 holds and
-- the outer join survives. Grouping by t.tournament_id puts every org-level row
-- into the single NULL group, which is the behaviour we want here.
-- =====================================================================
CREATE OR REPLACE VIEW v_org_financials AS
SELECT
    t.tournament_id
  , COALESCE(t.name, '(org-level -- not attributed to a tournament)') AS tournament
  , SUM(CASE WHEN tr.type = 'revenue' THEN tr.amount ELSE 0 END)          AS total_revenue
  , SUM(CASE WHEN tr.type = 'expense' THEN tr.amount ELSE 0 END)          AS total_expense
  , SUM(CASE WHEN tr.type = 'revenue' THEN tr.amount ELSE -tr.amount END) AS profit
FROM Transactions tr
LEFT JOIN Tournament t ON t.tournament_id = tr.tournament_id
JOIN Membership mb     ON mb.org_id       = tr.org_id
JOIN Users u           ON u.user_id       = mb.user_id
WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
  AND mb.role = 'admin'
  AND mb.left_date IS NULL
GROUP BY t.tournament_id, t.name;


-- =====================================================================
-- FIX 2 (test N2) -- v_outstanding_payments
--
-- Payments.status is NULLABLE, so  p.status <> 'paid'  was UNKNOWN for exactly
-- the payments nobody had got round to recording -- and UNKNOWN is not TRUE, so
-- they were dropped from the report that exists to find unpaid money.
-- COALESCE makes an unrecorded status count as unpaid, which is the safe
-- direction to be wrong in: an over-reported debt gets queried, an
-- under-reported one does not.
--
-- The three joins were already right. Note that the two LEFT JOINs must stay
-- LEFT: a staff payment has team_id NULL and a team payment has staff_user_id
-- NULL, so an inner join on either would delete half the payments.
-- =====================================================================
CREATE OR REPLACE VIEW v_outstanding_payments AS
SELECT
    p.payment_id
  , p.payee_type
  , COALESCE(u_payee.full_name, tm.team_name, '(payee not recorded)') AS payee
  , t.name AS tournament
  , p.amount
  , COALESCE(p.status, 'unrecorded') AS status
FROM Payments p
JOIN Tournament t       ON t.tournament_id = p.tournament_id
LEFT JOIN Users u_payee ON u_payee.user_id = p.staff_user_id
LEFT JOIN Teams tm      ON tm.team_id      = p.team_id
JOIN Membership mb      ON mb.org_id       = t.org_id
JOIN Users u            ON u.user_id       = mb.user_id
WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
  AND mb.role = 'admin'
  AND mb.left_date IS NULL
  AND COALESCE(p.status, '') <> 'paid';


-- =====================================================================
-- FIX 3 (test N3) -- v_my_profile
--
-- Roster.player_id is NOT NULL, so no Roster row was ever at risk -- but a
-- PLAYER with no Roster row is a dangling tuple, and the inner join deleted
-- their entire profile. Ten such players ship in 02_insert_data.sql: the solo
-- TFT and Rocket League entrants, who compete without a team.
--
-- The WHERE clause filters on pl only, so the outer joins are not re-innered.
-- The row-level security is unchanged: it was never the join that enforced it.
-- =====================================================================
CREATE OR REPLACE VIEW v_my_profile AS
SELECT
    pl.player_id
  , pl.ign
  , pl.real_name
  , pl.country
  , COALESCE(tm.team_name, '(free agent -- no roster entry)') AS team_name
  , r.jersey_number
  , r.join_date
  , r.leave_date
  , r.salary
FROM Players pl
LEFT JOIN Roster r ON r.player_id = pl.player_id
LEFT JOIN Teams tm ON tm.team_id  = r.team_id
WHERE pl.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);


-- =====================================================================
-- FIX 4 (test N4, guarded by N13) -- v_my_team_payouts
--
-- Two joins on nullable columns, and only one of them was wrong.
--
--   JOIN Teams tm ON tm.esports_org_id = eo.esports_org_id   -- STAYS INNER
--       Teams.esports_org_id is NULL for five of our eight teams. Those teams
--       have no parent org, so no parent org may see them. This join IS the row
--       filter; making it outer would leak every unaffiliated team to every
--       org. N13 checks that it did not.
--
--   JOIN Payments p ON p.team_id = tm.team_id                -- BECOMES LEFT
--       A team with no payout row vanished completely, so the org could not
--       tell "paid nothing" from "no such team".
--
-- p.payee_type = 'team' stays in the ON clause (rule 2). Moved to WHERE it
-- would discard exactly the unpaid teams the LEFT JOIN was added to keep.
-- amount is left NULL rather than coalesced to 0: nothing was paid, which is
-- not the same statement as "0.00 was paid".
-- =====================================================================
CREATE OR REPLACE VIEW v_my_team_payouts AS
SELECT
    eo.name   AS esports_org
  , tm.team_name
  , t.name    AS tournament
  , p.amount
  , CASE WHEN p.payment_id IS NULL THEN '(no payout recorded)'
         ELSE COALESCE(p.status, 'unrecorded')
    END AS status
  , p.payment_date
FROM EsportsOrg eo
JOIN Teams tm          ON tm.esports_org_id = eo.esports_org_id
LEFT JOIN Payments p   ON p.team_id         = tm.team_id
                      AND p.payee_type      = 'team'
LEFT JOIN Tournament t ON t.tournament_id   = p.tournament_id
WHERE eo.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);


-- =====================================================================
-- FIX 5 (test N5) -- v_tournament_ops
--
-- No join changes: every join in this view is on a NOT NULL column. The defect
-- is null propagation through CONCAT. StaffMatches.role is NULLABLE and
-- CONCAT(x, NULL, y) is NULL, so GROUP_CONCAT skipped the entry entirely and a
-- staff member assigned to the match simply was not listed on the view staff
-- use to run it.
--
-- Two further hardenings while we are here:
--   * MatchParticipant.placement is NULLABLE, so ORDER BY placement sorted
--     unplaced competitors FIRST -- they read as the winner. NULLs now sort
--     last.
--   * COALESCE(team_name, ign) is already correct, but a Competitor row that
--     satisfies neither branch would concat to NULL and vanish the same way, so
--     it gets a visible fallback too.
-- =====================================================================
CREATE OR REPLACE VIEW v_tournament_ops AS
SELECT
    t.name AS tournament
  , m.match_id
  , m.scheduled_time
  , (SELECT GROUP_CONCAT(COALESCE(tm2.team_name, pl2.ign, '(competitor not named)')
                         ORDER BY mp2.placement IS NULL, mp2.placement
                         SEPARATOR ' vs ')
     FROM MatchParticipant mp2
     JOIN Competitor c2    ON c2.competitor_id = mp2.competitor_id
     LEFT JOIN Teams tm2   ON tm2.team_id   = c2.team_id
     LEFT JOIN Players pl2 ON pl2.player_id = c2.player_id
     WHERE mp2.match_id = m.match_id)                       AS competitors
  , (SELECT GROUP_CONCAT(CONCAT(u.full_name, ' (',
                                COALESCE(sm.role, 'role not recorded'), ')')
                         SEPARATOR ', ')
     FROM StaffMatches sm
     JOIN Users u ON u.user_id = sm.user_id
     WHERE sm.match_id = m.match_id)                        AS staff_on_match
  , (SELECT COUNT(*) FROM CreatorMatches cm
     WHERE cm.match_id = m.match_id)                        AS creators_streaming
FROM `Match` m
JOIN Tournament t ON t.tournament_id = m.tournament_id;


-- =====================================================================
-- FIX 6 (test N6, guarded by N6-CTL) -- v_match_integrity
--
-- The LEFT JOIN here was always right -- it is what makes "no participants
-- recorded" reachable. The defect is in the CASE expression:
--
--     COUNT(DISTINCT mp.placement) <> COUNT(mp.competitor_id)
--
-- COUNT(DISTINCT x) ignores NULLs, so two competitors with no placement gave
-- 0 <> 2 and the view reported a duplicate placement that does not exist. On a
-- data-quality report a wrong diagnosis costs the same as a missing row: staff
-- go looking for the wrong fault.
--
-- Missing placements now get their own branch, tested BEFORE the duplicate
-- branch, and the duplicate test compares distinct non-NULL placements against
-- non-NULL placements so that it means what it says.
-- =====================================================================
CREATE OR REPLACE VIEW v_match_integrity AS
SELECT
    m.match_id
  , t.name   AS tournament
  , t.format
  , COUNT(mp.competitor_id)      AS participant_count
  , COUNT(DISTINCT mp.placement) AS distinct_placements
  , CASE
        WHEN COUNT(mp.competitor_id) = 0
            THEN 'no participants recorded'
        WHEN COUNT(mp.placement) <> COUNT(mp.competitor_id)
            THEN 'placement missing for at least one competitor'
        WHEN t.format = 'Single Elimination' AND COUNT(mp.competitor_id) <> 2
            THEN 'elimination match without exactly 2 competitors'
        WHEN COUNT(DISTINCT mp.placement) <> COUNT(mp.placement)
            THEN 'duplicate placement within one match'
        ELSE 'ok'
    END AS issue
FROM `Match` m
JOIN Tournament t             ON t.tournament_id = m.tournament_id
LEFT JOIN MatchParticipant mp ON mp.match_id     = m.match_id
GROUP BY m.match_id, t.name, t.format;


-- =====================================================================
-- HARDENING (no test of its own) -- v_public_standings
--
-- Every join here is already correct: the two nullable Competitor columns are
-- already LEFT JOINed, which is why this view is the model the others should
-- have followed. Two aggregate-level NULL exposures remain, and both are cheap
-- to close:
--   * MatchParticipant.points is NULLABLE, so SUM(points) is NULL for a
--     competitor whose points were never entered, and the row ranks below a
--     competitor with 0.
--   * MIN(placement) is NULL for the same reason and sorts FIRST under ASC,
--     which promotes an unrecorded competitor above a real winner on the
--     tie-break.
-- The row was never dropped, so this is not counted in the MEASURE.
-- =====================================================================
CREATE OR REPLACE VIEW v_public_standings AS
SELECT
    t.tournament_id
  , t.name   AS tournament
  , t.format
  , RANK() OVER (PARTITION BY t.tournament_id
                 ORDER BY COALESCE(SUM(mp.points), 0) DESC
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
GROUP BY t.tournament_id, t.name, t.format
       , c.competitor_id, c.competitor_type, tm.team_name, pl.ign;


-- #####################################################################
-- #  P A R T   B   --   the corrected queries
-- #
-- #  Drop-in replacements for Q1, Q7, Q8, Q9 and Q11 of
-- #  03_test_queries.sql, which is not modified this sprint. Tests N7-N11
-- #  measure the difference each one makes.
-- #####################################################################

-- ---------------------------------------------------------------------
-- Q1 corrected (test N7): SUM() over no rows is NULL, not 0, and NULL
-- arithmetic spreads through the whole profit column. A tournament with
-- expenses and no revenue reported profit = NULL instead of a loss, so a
-- "which events lost money" filter could never find it.
-- ---------------------------------------------------------------------
SELECT
    t.tournament_id
  , t.name
  , COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
              WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue'), 0) AS total_revenue
  , COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
              WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense'), 0) AS total_expense
  , COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
              WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue'), 0)
  - COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
              WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense'), 0) AS profit
FROM Tournament t
ORDER BY profit DESC;

-- Q1 companion: the org-level money Q1 can never show, because it is attached
-- to no tournament at all. Reported separately rather than left invisible.
SELECT
    '(org-level -- not attributed to a tournament)' AS scope
  , COALESCE(SUM(CASE WHEN type = 'revenue' THEN amount ELSE 0 END), 0) AS total_revenue
  , COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
  , COALESCE(SUM(CASE WHEN type = 'revenue' THEN amount ELSE -amount END), 0) AS profit
FROM Transactions
WHERE tournament_id IS NULL;


-- ---------------------------------------------------------------------
-- Q7 corrected (test N8): Match.scheduled_time is NULLABLE. If a tournament's
-- times were never entered, MAX() returns NULL, "scheduled_time = NULL" is
-- UNKNOWN for every row, and the tournament silently has no champion at all.
-- Picking the last match by an explicit deterministic ordering -- real times
-- first, then match_id as the tie-break -- always returns exactly one match per
-- tournament, whether the times are recorded or not.
-- ---------------------------------------------------------------------
SELECT
    COALESCE(tm.team_name, pl.ign, '(competitor not named)') AS champion
  , c.competitor_type
  , COUNT(*) AS tournaments_won
FROM `Match` m
JOIN Tournament t        ON t.tournament_id = m.tournament_id
JOIN MatchParticipant mp ON mp.match_id = m.match_id AND mp.placement = 1
JOIN Competitor c        ON c.competitor_id = mp.competitor_id
LEFT JOIN Teams tm       ON tm.team_id   = c.team_id
LEFT JOIN Players pl     ON pl.player_id = c.player_id
WHERE t.format = 'Single Elimination'
  AND m.match_id = (
      SELECT m2.match_id
      FROM `Match` m2
      WHERE m2.tournament_id = m.tournament_id
      ORDER BY m2.scheduled_time IS NULL, m2.scheduled_time DESC, m2.match_id DESC
      LIMIT 1
  )
GROUP BY c.competitor_id, c.competitor_type, tm.team_name, pl.ign
ORDER BY tournaments_won DESC, champion;


-- ---------------------------------------------------------------------
-- Q8 corrected (test N9): Payments.status is NULLABLE and NULL <> 'paid' is
-- UNKNOWN, so a debt nobody had recorded a status for was missing from the
-- report that exists to find unrecorded debts.
--
-- The two inner joins are deliberately left alone: staff_user_id and team_id
-- are the XOR pair, and each arm is meant to select one kind of payee. UNION
-- became UNION ALL -- plain UNION would silently merge a staff and a team debt
-- that happened to agree on amount, status and tournament.
-- ---------------------------------------------------------------------
SELECT 'staff' AS payee_type, u.full_name AS payee, t.name AS tournament
     , p.amount, COALESCE(p.status, 'unrecorded') AS status
FROM Payments p
JOIN Users u      ON u.user_id = p.staff_user_id
JOIN Tournament t ON t.tournament_id = p.tournament_id
WHERE COALESCE(p.status, '') <> 'paid'
UNION ALL
SELECT 'team' AS payee_type, tm.team_name AS payee, t.name AS tournament
     , p.amount, COALESCE(p.status, 'unrecorded') AS status
FROM Payments p
JOIN Teams tm     ON tm.team_id = p.team_id
JOIN Tournament t ON t.tournament_id = p.tournament_id
WHERE COALESCE(p.status, '') <> 'paid'
ORDER BY amount DESC;


-- ---------------------------------------------------------------------
-- Q9 corrected (test N10): x / 0 is NULL in MySQL rather than an error, and
-- MySQL sorts NULL last under DESC, so the player who has never died -- the
-- best K/D in the table -- was cut off by LIMIT 5. An undefined ratio is now
-- labelled and ranked first instead of silently discarded. NULLIF keeps the
-- division explicit about why the value is NULL.
-- ---------------------------------------------------------------------
SELECT
    pl.ign
  , ROUND(SUM(pms.kills) / NULLIF(SUM(pms.deaths), 0), 2) AS kd_ratio
  , CASE WHEN COALESCE(SUM(pms.deaths), 0) = 0
         THEN 'undefined -- no deaths recorded' ELSE '' END AS note
FROM Players pl
JOIN PlayerMatchStats pms ON pms.player_id = pl.player_id
GROUP BY pl.player_id, pl.ign
ORDER BY (COALESCE(SUM(pms.deaths), 0) = 0) DESC, kd_ratio DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- Q11 corrected (test N11): a sponsor whose contract has no Deliverables row
-- was dropped by the inner join -- and a sponsor who delivered nothing is
-- exactly the one a fulfilment report has to show. Both joins become LEFT and
-- COUNT(*) becomes COUNT(d.deliverable_id) so that "nothing delivered" reads as
-- 0 rather than 1.
--
-- c.party_type = 'sponsor' stays in the ON clause. In the WHERE clause it would
-- discard every sponsor with no sponsor contract, undoing the outer join.
-- ---------------------------------------------------------------------
SELECT
    s.company_name
  , COALESCE(d.status, '(no deliverable recorded)') AS status
  , COUNT(d.deliverable_id) AS num_deliverables
FROM Sponsors s
LEFT JOIN Contracts c    ON c.sponsor_id  = s.sponsor_id AND c.party_type = 'sponsor'
LEFT JOIN Deliverables d ON d.contract_id = c.contract_id
GROUP BY s.sponsor_id, s.company_name, d.status
ORDER BY s.company_name, status;

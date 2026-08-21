-- =====================================================================
USE design_project_370;


-- Q1: Is this tournament profitable? (revenue - expenses per tournament)
-- Sprint 5 null repair: SUM() over no rows is NULL, not 0, and NULL arithmetic
-- spreads through the whole profit column. A tournament with expenses and no
-- revenue reported profit = NULL instead of a loss, so a "which events lost
-- money" filter could never find it. Evidence: test N7 in 11_null_tests.sql.
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


-- Q2: Which creators are in event #1?
SELECT
    c.creator_id
  , c.twitchlink
  , c.instagram
  , c.twitter
  , ca.role
FROM CreatorAssignment ca
JOIN Creators c ON c.creator_id = ca.creator_id
WHERE ca.tournament_id = 1;


-- Q3: How many competitors are participating in each tournament?
-- (a competitor is a team OR a solo player, so this counts both kinds of event)
SELECT
    t.tournament_id
  , t.name
  , t.format
  , COUNT(r.competitor_id) AS competitors_registered
FROM Tournament t
LEFT JOIN Registration r ON r.tournament_id = t.tournament_id
GROUP BY t.tournament_id, t.name, t.format
ORDER BY competitors_registered DESC;


-- Q4: What organizations (esports orgs) are present in tournament #1?
-- Now goes through Competitor, since a registration is no longer a team directly.
SELECT DISTINCT
    eo.esports_org_id
  , eo.name
FROM Registration r
JOIN Competitor c  ON c.competitor_id = r.competitor_id
JOIN Teams tm      ON tm.team_id = c.team_id
JOIN EsportsOrg eo ON eo.esports_org_id = tm.esports_org_id
WHERE r.tournament_id = 1;


-- Q5: Which game is being played for tournament #3?
SELECT
    t.tournament_id
  , t.name
  , g.title AS game
FROM Tournament t
JOIN Game g ON g.game_id = t.game_id
WHERE t.tournament_id = 3;


-- Q6: Who are the top players in each game title? (by total kills, top listed first)
SELECT
    g.title AS game
  , pl.ign
  , SUM(pms.kills) AS total_kills
FROM PlayerMatchStats pms
JOIN `Match` m    ON m.match_id = pms.match_id
JOIN Tournament t ON t.tournament_id = m.tournament_id
JOIN Game g       ON g.game_id = t.game_id
JOIN Players pl   ON pl.player_id = pms.player_id
GROUP BY g.game_id, g.title, pl.player_id, pl.ign
ORDER BY g.title, total_kills DESC
LIMIT 5;


-- Q7: Who won the most tournaments? (champion = placement 1 in the final match)
-- Restricted to bracket formats: in a points-by-placement event the champion is
-- decided on total points, not by the last lobby -- that case is Q14.
-- The COALESCE means one query covers team champions and solo champions.
--
-- Sprint 5, two repairs in one (see 16_query_rewrites.sql):
--   null safety -- scheduled_time is NULLABLE. MAX() over all-NULL is NULL and
--     "scheduled_time = NULL" is UNKNOWN, so a tournament whose times were never
--     entered silently had no champion at all (test N8).
--   physical design -- the old dependent subquery re-ran once per outer row, so
--     no index could help it. Computing the final of every tournament once, as a
--     grouped derived table, cut rows examined from 502,451 to 7,102 (70.75x) on
--     370,910 rows with the index unchanged.
-- MAX() ignores NULLs, so agg.mx is NULL only when every match in that
-- tournament has a NULL time -- exactly what the OR arm catches.
SELECT
    COALESCE(tm.team_name, pl.ign, '(competitor not named)') AS champion
  , c.competitor_type
  , COUNT(*) AS tournaments_won
FROM `Match` m
JOIN (
        SELECT
            mm.tournament_id
          , MAX(mm.match_id) AS last_match_id
        FROM `Match` mm
        JOIN (
                SELECT
                    tournament_id
                  , MAX(scheduled_time) AS mx
                FROM `Match`
                GROUP BY tournament_id
             ) agg ON agg.tournament_id = mm.tournament_id
        WHERE mm.scheduled_time = agg.mx
           OR (agg.mx IS NULL AND mm.scheduled_time IS NULL)
        GROUP BY mm.tournament_id
     ) lm                ON lm.last_match_id = m.match_id
JOIN Tournament t        ON t.tournament_id = m.tournament_id
JOIN MatchParticipant mp ON mp.match_id = m.match_id AND mp.placement = 1
JOIN Competitor c        ON c.competitor_id = mp.competitor_id
LEFT JOIN Teams tm       ON tm.team_id   = c.team_id
LEFT JOIN Players pl     ON pl.player_id = c.player_id
WHERE t.format = 'Single Elimination'
GROUP BY c.competitor_id, c.competitor_type, tm.team_name, pl.ign
ORDER BY tournaments_won DESC, champion;


-- Q8: Who is still owed money? (staff and teams with unpaid status)
-- Sprint 5 null repair: Payments.status is NULLABLE and NULL <> 'paid' is
-- UNKNOWN, not TRUE, so a debt nobody had recorded a status for was missing from
-- the report that exists to find unrecorded debts -- 1,887.00 of it (test N9).
-- The two inner joins are deliberately left alone: staff_user_id and team_id are
-- the XOR pair and each arm selects one kind of payee. UNION became UNION ALL --
-- plain UNION would silently merge a staff and a team debt that happened to
-- agree on amount, status and tournament.
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


-- Q9: Which players have the highest and lowest K/D ratio? (highest first, lowest last)
-- Sprint 5 null repair: x / 0 is NULL in MySQL rather than an error, and MySQL
-- sorts NULL last under DESC, so the player who has never died -- the best K/D
-- in the table -- was cut off by LIMIT 5. An undefined ratio is now labelled and
-- ranked first instead of silently discarded (test N10).
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


-- Q10: Who has admin power? (admin members of an organization)
SELECT DISTINCT
    u.user_id
  , u.full_name
  , m.role
  , o.org_name
FROM Users u
JOIN Membership m   ON m.user_id = u.user_id
JOIN Organization o ON o.org_id  = m.org_id
WHERE m.role = 'admin';


-- Q11: Were sponsor deliverables fulfilled? (count per sponsor, per status)
-- Sprint 5 null repair: a sponsor whose contract has no Deliverables row was
-- dropped by the inner join -- and a sponsor who delivered nothing is exactly the
-- one a fulfilment report has to show. 7,500.00 of contract value was invisible
-- (test N11). COUNT(*) became COUNT(d.deliverable_id) so "nothing delivered"
-- reads as 0 rather than 1. c.party_type stays in the ON clause: in WHERE it
-- would discard every sponsor with no sponsor contract, undoing the outer join.
SELECT
    s.company_name
  , COALESCE(d.status, '(no deliverable recorded)') AS status
  , COUNT(d.deliverable_id) AS num_deliverables
FROM Sponsors s
LEFT JOIN Contracts c    ON c.sponsor_id  = s.sponsor_id AND c.party_type = 'sponsor'
LEFT JOIN Deliverables d ON d.contract_id = c.contract_id
GROUP BY s.sponsor_id, s.company_name, d.status
ORDER BY s.company_name, status;


-- Q12: Which sponsors are worth renewing? (total spend + deliverable fulfillment)
SELECT
    s.company_name
  , (SELECT SUM(c.total_value)
     FROM Contracts c
     WHERE c.sponsor_id = s.sponsor_id AND c.party_type = 'sponsor') AS total_spend
  , (SELECT COUNT(*)
     FROM Deliverables d
     JOIN Contracts c ON d.contract_id = c.contract_id
     WHERE c.sponsor_id = s.sponsor_id) AS deliverables_total
  , (SELECT COUNT(*)
     FROM Deliverables d
     JOIN Contracts c ON d.contract_id = c.contract_id
     WHERE c.sponsor_id = s.sponsor_id AND d.status = 'fulfilled') AS deliverables_fulfilled
FROM Sponsors s
ORDER BY total_spend DESC;


-- =====================================================================
-- GENERALIZED RESULTS MODEL (Sprint 3 goal)
-- Q13-Q15 are the evidence that the results model is no longer limited to
-- two teams per match. All three read the same MatchParticipant relation.
-- =====================================================================

-- Q13: FINAL STANDINGS for every tournament, whatever its format or size.
-- This is the success criterion: one query returns the standings of an
-- 8-team Valorant bracket, an 8-player TFT lobby series, and a 1v1 duel,
-- because "who competed and how they placed" is now rows, not columns.
-- Ties are broken by the competitor's best single-match placement.
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
       , c.competitor_id, c.competitor_type, tm.team_name, pl.ign
ORDER BY t.tournament_id, SUM(mp.points) DESC, MIN(mp.placement) ASC;


-- Q14: The 8-player TFT lobby, exactly as stored (match 11).
-- Eight competitors in ONE match -- impossible under team1_id/team2_id.
SELECT
    m.match_id
  , m.scheduled_time
  , mp.placement
  , pl.ign AS player
  , mp.points
FROM MatchParticipant mp
JOIN `Match` m   ON m.match_id = mp.match_id
JOIN Competitor c ON c.competitor_id = mp.competitor_id
JOIN Players pl   ON pl.player_id = c.player_id
WHERE m.match_id = 11
ORDER BY mp.placement;


-- Q15: The Rocket League 1v1 series -- one player per side, no team rows at all.
SELECT
    m.match_id
  , m.scheduled_time
  , m.final_score
  , MAX(CASE WHEN mp.placement = 1 THEN pl.ign END) AS winner
  , MAX(CASE WHEN mp.placement = 2 THEN pl.ign END) AS loser
FROM `Match` m
JOIN MatchParticipant mp ON mp.match_id = m.match_id
JOIN Competitor c        ON c.competitor_id = mp.competitor_id
JOIN Players pl          ON pl.player_id = c.player_id
WHERE m.tournament_id = 4
GROUP BY m.match_id, m.scheduled_time, m.final_score
ORDER BY m.scheduled_time;

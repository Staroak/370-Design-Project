-- =====================================================================
USE design_project_370;


-- Q1: Is this tournament profitable? (revenue - expenses per tournament)
SELECT
    t.tournament_id
  , t.name
  , (SELECT SUM(tr.amount) FROM Transactions tr
     WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue') AS total_revenue
  , (SELECT SUM(tr.amount) FROM Transactions tr
     WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense') AS total_expense
  , (SELECT SUM(tr.amount) FROM Transactions tr
     WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue')
  - (SELECT SUM(tr.amount) FROM Transactions tr
     WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense') AS profit
FROM Tournament t
ORDER BY profit DESC;


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
SELECT
    COALESCE(tm.team_name, pl.ign) AS champion
  , c.competitor_type
  , COUNT(*) AS tournaments_won
FROM `Match` m
JOIN Tournament t         ON t.tournament_id = m.tournament_id
JOIN MatchParticipant mp  ON mp.match_id = m.match_id AND mp.placement = 1
JOIN Competitor c         ON c.competitor_id = mp.competitor_id
LEFT JOIN Teams tm        ON tm.team_id   = c.team_id
LEFT JOIN Players pl      ON pl.player_id = c.player_id
WHERE t.format = 'Single Elimination'
  AND m.scheduled_time = (
      SELECT MAX(m2.scheduled_time)
      FROM `Match` m2
      WHERE m2.tournament_id = m.tournament_id
  )
GROUP BY c.competitor_id, c.competitor_type, tm.team_name, pl.ign
ORDER BY tournaments_won DESC, champion;


-- Q8: Who is still owed money? (staff and teams with unpaid status)
SELECT 'staff' AS payee_type, u.full_name AS payee, t.name AS tournament, p.amount, p.status
FROM Payments p
JOIN Users u      ON u.user_id = p.staff_user_id
JOIN Tournament t ON t.tournament_id = p.tournament_id
WHERE p.status <> 'paid'
UNION
SELECT 'team' AS payee_type, tm.team_name AS payee, t.name AS tournament, p.amount, p.status
FROM Payments p
JOIN Teams tm     ON tm.team_id = p.team_id
JOIN Tournament t ON t.tournament_id = p.tournament_id
WHERE p.status <> 'paid'
ORDER BY amount DESC;


-- Q9: Which players have the highest and lowest K/D ratio? (highest first, lowest last)
SELECT
    pl.ign
  , ROUND(SUM(pms.kills) / SUM(pms.deaths), 2) AS kd_ratio
FROM Players pl
JOIN PlayerMatchStats pms ON pms.player_id = pl.player_id
GROUP BY pl.player_id, pl.ign
ORDER BY kd_ratio DESC
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
SELECT
    s.company_name
  , d.status
  , COUNT(*) AS num_deliverables
FROM Sponsors s
JOIN Contracts c    ON c.sponsor_id = s.sponsor_id AND c.party_type = 'sponsor'
JOIN Deliverables d ON d.contract_id = c.contract_id
GROUP BY s.sponsor_id, s.company_name, d.status
ORDER BY s.company_name, d.status;


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

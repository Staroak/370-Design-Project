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


-- Q2: How many creators are in event #1?
SELECT COUNT(*) AS creator_count
FROM CreatorAssignment
WHERE tournament_id = 1;


-- Q3: How many teams are participating in each tournament?
SELECT
    t.tournament_id
  , t.name
  , COUNT(r.team_id) AS teams_registered
FROM Tournament t
LEFT JOIN Registration r ON r.tournament_id = t.tournament_id
GROUP BY t.tournament_id, t.name
ORDER BY teams_registered DESC;


-- Q4: What organizations (esports orgs) are present in tournament #1?
SELECT DISTINCT
    eo.esports_org_id
  , eo.name
FROM Registration r
JOIN Teams tm      ON tm.team_id = r.team_id
JOIN EsportsOrg eo ON eo.esports_org_id = tm.esports_org_id
WHERE r.tournament_id = 1;


-- Q5: Which game is being played for tournament #5?
SELECT
    t.tournament_id
  , t.name
  , g.title AS game
FROM Tournament t
JOIN Game g ON g.game_id = t.game_id
WHERE t.tournament_id = 5;


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
ORDER BY g.title, total_kills DESC;


-- Q7: Which teams won the most tournaments? (champion = winner of the final match)
SELECT
    tm.team_name
  , COUNT(*) AS tournaments_won
FROM `Match` m
JOIN Teams tm ON tm.team_id = m.winner_team_id
WHERE m.scheduled_time = (
    SELECT MAX(m2.scheduled_time)
    FROM `Match` m2
    WHERE m2.tournament_id = m.tournament_id
)
GROUP BY tm.team_id, tm.team_name
ORDER BY tournaments_won DESC;


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
ORDER BY kd_ratio DESC;


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

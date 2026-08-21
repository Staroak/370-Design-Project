USE design_project_370;

DROP TABLE IF EXISTS null_results;
CREATE TABLE null_results (
    seq       INT           NOT NULL AUTO_INCREMENT
  , test      VARCHAR(12)   NOT NULL
  , kind      VARCHAR(10)   NOT NULL      -- preflight / view / query / control / summary
  , target    VARCHAR(48)   NOT NULL      -- the view or query under test
  , verdict   VARCHAR(8)    NOT NULL      -- GAP / OK / FAIL
  , evidence  VARCHAR(255)                -- the numbers the verdict came from
  , detail    VARCHAR(255)
  , PRIMARY KEY (seq)
);


-- #####################################################################
-- #  P R E F L I G H T
-- #
-- #  The nullable-column inventory, read out of the catalogue rather than
-- #  transcribed by hand from 01_create_tables.sql.
-- #####################################################################

-- Every nullable column in the schema. The two *_results scratch tables that
-- 08 and 11 create for their own verdicts are excluded -- they are not part of
-- the design under audit.
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND IS_NULLABLE = 'YES'
  AND TABLE_NAME NOT LIKE '%\_results'
  AND TABLE_NAME IN (SELECT TABLE_NAME FROM information_schema.TABLES
                     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- The subset that matters most: nullable FOREIGN KEYS. These are the columns
-- an inner join can silently drop rows on.
SELECT k.TABLE_NAME, k.COLUMN_NAME, k.REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.COLUMNS c
     ON  c.TABLE_SCHEMA = k.TABLE_SCHEMA
     AND c.TABLE_NAME   = k.TABLE_NAME
     AND c.COLUMN_NAME  = k.COLUMN_NAME
WHERE k.TABLE_SCHEMA = DATABASE()
  AND k.REFERENCED_TABLE_NAME IS NOT NULL
  AND c.IS_NULLABLE = 'YES'
ORDER BY k.TABLE_NAME, k.COLUMN_NAME;

SELECT COUNT(*) INTO @p_nullable
FROM information_schema.COLUMNS c
JOIN information_schema.TABLES t
     ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE c.TABLE_SCHEMA = DATABASE()
  AND c.IS_NULLABLE = 'YES'
  AND t.TABLE_TYPE = 'BASE TABLE'
  AND c.TABLE_NAME NOT LIKE '%\_results';

SELECT COUNT(*) INTO @p_null_fk
FROM information_schema.KEY_COLUMN_USAGE k
JOIN information_schema.COLUMNS c
     ON  c.TABLE_SCHEMA = k.TABLE_SCHEMA
     AND c.TABLE_NAME   = k.TABLE_NAME
     AND c.COLUMN_NAME  = k.COLUMN_NAME
WHERE k.TABLE_SCHEMA = DATABASE()
  AND k.REFERENCED_TABLE_NAME IS NOT NULL
  AND c.IS_NULLABLE = 'YES';

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('P0-nullfk', 'preflight', '01_create_tables.sql', IF(@p_null_fk = 9, 'OK', 'FAIL'),
 CONCAT(@p_null_fk, ' nullable foreign keys, ', @p_nullable, ' nullable columns in all'),
 'Teams.esports_org_id, Competitor.team_id, Competitor.player_id, Contracts.tournament_id/sponsor_id/creator_id, Transactions.tournament_id, Payments.staff_user_id/team_id');

SELECT COUNT(*) INTO @p_views
FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE();

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('P0-views', 'preflight', '04_views.sql', IF(@p_views = 16, 'OK', 'FAIL'),
 CONCAT('views present: ', @p_views),
 'the MEASURE is stated over 16 role views; a different number means the run is not comparable');

-- Which mode are we in? Read it off the catalogue, do not assume.
SELECT COUNT(*) INTO @p_fixed
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'v_org_financials'
  AND VIEW_DEFINITION LIKE '%left join%';

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('P0-mode', 'preflight', '12_null_fixes.sql', 'OK',
 CONCAT('12_null_fixes.sql applied: ', IF(@p_fixed > 0, 'yes', 'no')),
 'detected from information_schema.VIEWS, not from a flag passed in');

-- Tournament.game_id is NOT NULL. Recorded because it was on the suspect list
-- and is the one candidate that turned out to be safe: v_public_schedule and
-- Q5 cannot drop a tournament for want of a game.
SELECT COUNT(*) INTO @p_tgame
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Tournament'
  AND COLUMN_NAME = 'game_id' AND IS_NULLABLE = 'NO';

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('P0-tgame', 'preflight', 'Tournament.game_id', IF(@p_tgame = 1, 'OK', 'FAIL'),
 CONCAT('Tournament.game_id declared NOT NULL: ', @p_tgame),
 'so JOIN Game in v_public_schedule / v_public_player_stats / Q5 / Q6 cannot drop a row');


-- #####################################################################
-- #  V I E W   T E S T S
-- #
-- #  One block per view that loses rows or values. Each compares the shipped
-- #  view against the null-safe rewrite of itself.
-- #####################################################################

-- =====================================================================
-- N1 -- v_org_financials hides org-level money
--
--     FROM Transactions tr
--     JOIN Tournament t ON t.tournament_id = tr.tournament_id
--
-- Transactions.tournament_id is NULLABLE, and deliberately so: the Sprint 1
-- write-up says in as many words "tournament_id may be null (org-level
-- transactions)". Office rent, an annual software licence and a blanket
-- sponsorship are all org-level. The inner join deletes every one of them from
-- the admin's profit report, and the report gives no sign that it happened.
--
-- This is the worst of the sixteen: the number an organizer makes decisions on
-- is wrong, and it is wrong in the safe-looking direction (expenses vanish, so
-- the org looks more profitable than it is).
-- =====================================================================
START TRANSACTION;
UPDATE Users SET db_username = 'root' WHERE user_id = 9;   -- the org-1 admin

INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, NULL, 'expense', 'null-test office rent', 12000.00, CURRENT_DATE);

-- what the shipped view shows
SELECT COUNT(*), COALESCE(SUM(total_expense), 0)
  INTO @n1_rows_view, @n1_exp_view
FROM v_org_financials;

-- what a null-safe rewrite shows
SELECT COUNT(*), COALESCE(SUM(x.total_expense), 0)
  INTO @n1_rows_fix, @n1_exp_fix
FROM (
    SELECT t.tournament_id
         , SUM(CASE WHEN tr.type = 'expense' THEN tr.amount ELSE 0 END) AS total_expense
    FROM Transactions tr
    LEFT JOIN Tournament t ON t.tournament_id = tr.tournament_id
    JOIN Membership mb     ON mb.org_id       = tr.org_id
    JOIN Users u           ON u.user_id       = mb.user_id
    WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
      AND mb.role = 'admin'
      AND mb.left_date IS NULL
    GROUP BY t.tournament_id
) x;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N1', 'view', 'v_org_financials', IF(@n1_exp_fix > @n1_exp_view, 'GAP', 'OK'),
 CONCAT('rows ', @n1_rows_view, ' vs ', @n1_rows_fix,
        '; expense visible ', @n1_exp_view, ' of ', @n1_exp_fix,
        ' -- hidden: ', @n1_exp_fix - @n1_exp_view),
 'inner join on the NULLABLE Transactions.tournament_id erased an org-level expense from the profit report');


-- =====================================================================
-- N2 -- v_outstanding_payments drops the payments most likely to be outstanding
--
--     WHERE ... AND p.status <> 'paid'
--
-- Payments.status is NULLABLE. NULL <> 'paid' is UNKNOWN, not TRUE, so a
-- payment whose status was never recorded is filtered out of the report whose
-- entire purpose is to find money that has not been paid. The three joins in
-- this view are already correct; the bug is in the WHERE clause, which is why
-- an audit that only looks at JOIN keywords misses it.
-- =====================================================================
START TRANSACTION;
UPDATE Users SET db_username = 'root' WHERE user_id = 9;

INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('staff', 12, NULL, 2, 999.00, NULL, NULL);

SELECT COUNT(*), COALESCE(SUM(amount), 0)
  INTO @n2_rows_view, @n2_amt_view
FROM v_outstanding_payments;

SELECT COUNT(*), COALESCE(SUM(x.amount), 0)
  INTO @n2_rows_fix, @n2_amt_fix
FROM (
    SELECT p.payment_id, p.amount
    FROM Payments p
    JOIN Tournament t       ON t.tournament_id = p.tournament_id
    LEFT JOIN Users u_payee ON u_payee.user_id = p.staff_user_id
    LEFT JOIN Teams tm      ON tm.team_id      = p.team_id
    JOIN Membership mb      ON mb.org_id       = t.org_id
    JOIN Users u            ON u.user_id       = mb.user_id
    WHERE u.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1)
      AND mb.role = 'admin'
      AND mb.left_date IS NULL
      AND COALESCE(p.status, '') <> 'paid'
) x;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N2', 'view', 'v_outstanding_payments', IF(@n2_rows_fix > @n2_rows_view, 'GAP', 'OK'),
 CONCAT('rows ', @n2_rows_view, ' vs ', @n2_rows_fix,
        '; amount owed shown ', @n2_amt_view, ' of ', @n2_amt_fix,
        ' -- hidden: ', @n2_amt_fix - @n2_amt_view),
 'status <> ''paid'' evaluates to UNKNOWN for a NULL status, so an unrecorded debt is not reported as owed');


-- =====================================================================
-- N3 -- v_my_profile erases the whole profile of a player with no roster row
--
--     FROM Players pl JOIN Roster r ON r.player_id = pl.player_id
--
-- Roster.player_id is NOT NULL, so no Roster row is lost -- but a PLAYER with
-- no Roster row at all is a dangling tuple and the inner join deletes them.
-- The view is a self-service profile page: ign, real name and country exist in
-- Players and are shown to nobody.
--
-- Nothing is injected for this test. 02_insert_data.sql already ships ten such
-- players: the eight solo TFT entrants and the two Rocket League duellists
-- (player_id 47-56) compete as 'player' competitors and are on no team.
-- =====================================================================
START TRANSACTION;
UPDATE Players SET db_username = 'root' WHERE player_id = 47;   -- Setsuko#TFT, solo

SELECT COUNT(*) INTO @n3_rows_view FROM v_my_profile;

SELECT COUNT(*) INTO @n3_rows_fix
FROM Players pl
LEFT JOIN Roster r ON r.player_id = pl.player_id
LEFT JOIN Teams tm ON tm.team_id  = r.team_id
WHERE pl.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);

SELECT COUNT(*) INTO @n3_rosterless
FROM Players pl
LEFT JOIN Roster r ON r.player_id = pl.player_id
WHERE r.player_id IS NULL;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N3', 'view', 'v_my_profile', IF(@n3_rows_fix > @n3_rows_view, 'GAP', 'OK'),
 CONCAT('own profile rows ', @n3_rows_view, ' vs ', @n3_rows_fix,
        '; players with no Roster row in shipped data: ', @n3_rosterless),
 'a solo competitor logs in and sees an empty page; nothing was injected, the ten rosterless players are real data');


-- =====================================================================
-- N4 -- v_my_team_payouts hides a team that was never paid
--
--     JOIN Payments p ON p.team_id = tm.team_id AND p.payee_type = 'team'
--
-- A parent org's team with no Payments row is a dangling tuple and disappears
-- entirely. The org cannot distinguish "this team was paid nothing" from "this
-- team does not exist", which is exactly the question a payout report answers.
--
-- Again no injection: EsportsOrg 2 (QOR) owns teams 4 and 5, and team 5
-- (MENAces) has no Payments row in 02_insert_data.sql.
-- =====================================================================
START TRANSACTION;
UPDATE EsportsOrg SET db_username = 'root' WHERE esports_org_id = 2;   -- QOR

SELECT COUNT(DISTINCT team_name) INTO @n4_teams_view FROM v_my_team_payouts;

SELECT COUNT(DISTINCT tm.team_name) INTO @n4_teams_fix
FROM EsportsOrg eo
JOIN Teams tm          ON tm.esports_org_id = eo.esports_org_id
LEFT JOIN Payments p   ON p.team_id = tm.team_id AND p.payee_type = 'team'
LEFT JOIN Tournament t ON t.tournament_id = p.tournament_id
WHERE eo.db_username = SUBSTRING_INDEX(SESSION_USER(), '@', 1);

SELECT COUNT(*) INTO @n4_owned FROM Teams WHERE esports_org_id = 2;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N4', 'view', 'v_my_team_payouts', IF(@n4_teams_fix > @n4_teams_view, 'GAP', 'OK'),
 CONCAT('teams visible to their own parent org: ', @n4_teams_view,
        ' of ', @n4_teams_fix, ' (', @n4_owned, ' owned)'),
 'a team with zero payouts is indistinguishable from a team that does not exist');


-- =====================================================================
-- N5 -- v_tournament_ops deletes a staff member from the crew list
--
--     CONCAT(u.full_name, ' (', sm.role, ')')
--
-- Not a join at all: StaffMatches.role is NULLABLE and CONCAT returns NULL if
-- any argument is NULL, so the whole entry becomes NULL and GROUP_CONCAT skips
-- it. A moderator whose role was not typed in is not shown as "unknown role" --
-- they are not shown at all, on the view staff use to run the event.
-- =====================================================================
START TRANSACTION;
INSERT INTO StaffMatches (user_id, match_id, role) VALUES (12, 7, NULL);

SELECT staff_on_match INTO @n5_txt FROM v_tournament_ops WHERE match_id = 7;
SELECT COUNT(*) INTO @n5_real FROM StaffMatches WHERE match_id = 7;
ROLLBACK;

-- User variables survive ROLLBACK, so the arithmetic is done afterwards.
SET @n5_listed = IF(@n5_txt IS NULL, 0,
                    CHAR_LENGTH(@n5_txt) - CHAR_LENGTH(REPLACE(@n5_txt, ',', '')) + 1);

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N5', 'view', 'v_tournament_ops', IF(@n5_real > @n5_listed, 'GAP', 'OK'),
 CONCAT('staff listed for match 7: ', @n5_listed, ' of ', @n5_real, ' assigned; list = ',
        IFNULL(@n5_txt, 'NULL')),
 'CONCAT with a NULL role yields NULL and GROUP_CONCAT drops it -- null propagation, not a dangling tuple');


-- =====================================================================
-- N6 -- v_match_integrity reports the wrong fault for a missing placement
--
--     COUNT(DISTINCT mp.placement) <> COUNT(mp.competitor_id)
--
-- MatchParticipant.placement is NULLABLE and COUNT(DISTINCT x) ignores NULLs.
-- Two competitors with no placement recorded give 0 <> 2, and the view reports
-- "duplicate placement within one match" when there is no duplicate at all.
-- The row is not dropped -- the DIAGNOSIS is wrong, which on a data-quality
-- report is the same kind of damage: staff go looking for the wrong fault.
--
-- N6-CTL is the other half: the fix must still catch a REAL duplicate.
-- =====================================================================
START TRANSACTION;
INSERT INTO `Match` (tournament_id, scheduled_time, final_score)
VALUES (1, '2026-03-15 10:00:00', '13-5');
SET @n6a := LAST_INSERT_ID();
INSERT INTO MatchParticipant (match_id, competitor_id, placement, points)
VALUES (@n6a, 3, NULL, 0), (@n6a, 6, NULL, 0);          -- placements not recorded

INSERT INTO `Match` (tournament_id, scheduled_time, final_score)
VALUES (1, '2026-03-15 11:00:00', '13-5');
SET @n6b := LAST_INSERT_ID();
INSERT INTO MatchParticipant (match_id, competitor_id, placement, points)
VALUES (@n6b, 3, 1, 1), (@n6b, 6, 1, 1);                -- a genuine duplicate

SELECT issue INTO @n6_issue_missing FROM v_match_integrity WHERE match_id = @n6a;
SELECT issue INTO @n6_issue_dup     FROM v_match_integrity WHERE match_id = @n6b;

SELECT COUNT(*) INTO @n6_real_dupes FROM (
    SELECT placement
    FROM MatchParticipant
    WHERE match_id = @n6a AND placement IS NOT NULL
    GROUP BY placement HAVING COUNT(*) > 1
) d;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N6', 'view', 'v_match_integrity',
 IF(@n6_real_dupes = 0 AND @n6_issue_missing = 'duplicate placement within one match', 'GAP', 'OK'),
 CONCAT('reported "', @n6_issue_missing, '" with ', @n6_real_dupes, ' actual duplicates'),
 'COUNT(DISTINCT placement) ignores NULLs, so two unrecorded placements are misreported as two identical ones');

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N6-CTL', 'control', 'v_match_integrity',
 IF(@n6_issue_dup = 'duplicate placement within one match', 'OK', 'FAIL'),
 CONCAT('a real duplicate is still reported as: "', @n6_issue_dup, '"'),
 'the null-safe rewrite must not stop detecting the fault it was written for');


-- #####################################################################
-- #  Q U E R Y   T E S T S   (03_test_queries.sql)
-- #
-- #  03_test_queries.sql is not modified by this sprint, so these stay GAP in
-- #  both modes on purpose. The drop-in rewrites are Part B of
-- #  12_null_fixes.sql and their output is at the top of the transcript.
-- #####################################################################

-- =====================================================================
-- N7 -- Q1 reports a loss as NULL
--
--     (SELECT SUM(...revenue...)) - (SELECT SUM(...expense...)) AS profit
--
-- SUM() over an empty set is NULL, not 0, and NULL - 4000 is NULL. A
-- tournament that took no revenue at all reports profit = NULL rather than the
-- loss it actually made, and any filter of the form "profit < 0" -- the way an
-- organizer would look for the events that lost money -- never sees it.
-- =====================================================================
START TRANSACTION;
INSERT INTO Tournament (org_id, game_id, name, start_date, end_date, format, status, prize_pool)
VALUES (1, 1, 'NULL-test Invitational', '2026-06-01', '2026-06-02',
        'Single Elimination', 'completed', 0.00);
SET @n7_t := LAST_INSERT_ID();

INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, @n7_t, 'expense', 'null-test production', 4000.00, '2026-06-02');

-- Q1's own profit expression, verbatim
SELECT (SELECT SUM(tr.amount) FROM Transactions tr
        WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue')
     - (SELECT SUM(tr.amount) FROM Transactions tr
        WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense')
  INTO @n7_profit_asis
FROM Tournament t WHERE t.tournament_id = @n7_t;

SELECT COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
                 WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue'), 0)
     - COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
                 WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense'), 0)
  INTO @n7_profit_fix
FROM Tournament t WHERE t.tournament_id = @n7_t;

-- how many loss-making tournaments each version can find
SELECT COUNT(*) INTO @n7_loss_asis FROM Tournament t
WHERE ( (SELECT SUM(tr.amount) FROM Transactions tr
         WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue')
      - (SELECT SUM(tr.amount) FROM Transactions tr
         WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense') ) < 0;

SELECT COUNT(*) INTO @n7_loss_fix FROM Tournament t
WHERE ( COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
                  WHERE tr.tournament_id = t.tournament_id AND tr.type = 'revenue'), 0)
      - COALESCE((SELECT SUM(tr.amount) FROM Transactions tr
                  WHERE tr.tournament_id = t.tournament_id AND tr.type = 'expense'), 0) ) < 0;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N7', 'query', 'Q1 profitability',
 IF(@n7_loss_fix > @n7_loss_asis, 'GAP', 'OK'),
 CONCAT('profit reported: ', IFNULL(CAST(@n7_profit_asis AS CHAR), 'NULL'),
        ', actual: ', @n7_profit_fix,
        '; loss-making tournaments found ', @n7_loss_asis, ' of ', @n7_loss_fix),
 'SUM() of no rows is NULL and NULL arithmetic spreads; wrap both subqueries in COALESCE(...,0)');


-- =====================================================================
-- N8 -- Q7 loses a tournament's champion when the final has no scheduled time
--
--     AND m.scheduled_time = (SELECT MAX(m2.scheduled_time) FROM `Match` m2 ...)
--
-- Match.scheduled_time is NULLABLE. If the times were never entered, MAX()
-- returns NULL, "scheduled_time = NULL" is UNKNOWN for every row, and the whole
-- tournament silently has no champion. The bracket, the results and the winner
-- are all in the database; the query just cannot reach them.
-- =====================================================================
START TRANSACTION;
-- before: the query finds the 1v1 champion of tournament 4
SELECT COUNT(*) INTO @n8_before FROM (
    SELECT c.competitor_id
    FROM `Match` m
    JOIN Tournament t        ON t.tournament_id = m.tournament_id
    JOIN MatchParticipant mp ON mp.match_id = m.match_id AND mp.placement = 1
    JOIN Competitor c        ON c.competitor_id = mp.competitor_id
    WHERE t.format = 'Single Elimination'
      AND m.tournament_id = 4
      AND m.scheduled_time = (SELECT MAX(m2.scheduled_time) FROM `Match` m2
                              WHERE m2.tournament_id = m.tournament_id)
) x;

UPDATE `Match` SET scheduled_time = NULL WHERE tournament_id = 4;

SELECT COUNT(*) INTO @n8_asis FROM (
    SELECT c.competitor_id
    FROM `Match` m
    JOIN Tournament t        ON t.tournament_id = m.tournament_id
    JOIN MatchParticipant mp ON mp.match_id = m.match_id AND mp.placement = 1
    JOIN Competitor c        ON c.competitor_id = mp.competitor_id
    WHERE t.format = 'Single Elimination'
      AND m.tournament_id = 4
      AND m.scheduled_time = (SELECT MAX(m2.scheduled_time) FROM `Match` m2
                              WHERE m2.tournament_id = m.tournament_id)
) x;

-- null-safe: pick the last match deterministically, NULL times sorted last
SELECT COUNT(*) INTO @n8_fix FROM (
    SELECT c.competitor_id
    FROM `Match` m
    JOIN Tournament t        ON t.tournament_id = m.tournament_id
    JOIN MatchParticipant mp ON mp.match_id = m.match_id AND mp.placement = 1
    JOIN Competitor c        ON c.competitor_id = mp.competitor_id
    WHERE t.format = 'Single Elimination'
      AND m.tournament_id = 4
      AND m.match_id = (SELECT m2.match_id FROM `Match` m2
                        WHERE m2.tournament_id = m.tournament_id
                        ORDER BY m2.scheduled_time IS NULL, m2.scheduled_time DESC,
                                 m2.match_id DESC
                        LIMIT 1)
) x;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N8', 'query', 'Q7 tournaments won',
 IF(@n8_fix > @n8_asis, 'GAP', 'OK'),
 CONCAT('champions of tournament 4: ', @n8_before, ' with times, ', @n8_asis,
        ' after the times are NULL, ', @n8_fix, ' null-safe'),
 'MAX() over all-NULL times is NULL and "= NULL" is UNKNOWN; MatchParticipant.placement = 1 has the same exposure');


-- =====================================================================
-- N9 -- Q8 has the same NULL-status hole as v_outstanding_payments
--
-- Both UNION arms end in  WHERE p.status <> 'paid'. The two inner joins on
-- Payments.staff_user_id / Payments.team_id are CORRECT: each arm deliberately
-- selects one kind of payee, and a NULL there means "not this kind". The bug is
-- the predicate, in both arms.
-- =====================================================================
START TRANSACTION;
INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('staff', 12,   NULL, 2, 999.00, NULL, NULL)
     , ('team',  NULL, 3,    1, 888.00, NULL, NULL);

SELECT COUNT(*), COALESCE(SUM(amount), 0) INTO @n9_rows_asis, @n9_amt_asis FROM (
    SELECT 'staff' AS payee_type, u.full_name AS payee, t.name AS tournament, p.amount, p.status
    FROM Payments p
    JOIN Users u      ON u.user_id = p.staff_user_id
    JOIN Tournament t ON t.tournament_id = p.tournament_id
    WHERE p.status <> 'paid'
    UNION
    SELECT 'team', tm.team_name, t.name, p.amount, p.status
    FROM Payments p
    JOIN Teams tm     ON tm.team_id = p.team_id
    JOIN Tournament t ON t.tournament_id = p.tournament_id
    WHERE p.status <> 'paid'
) x;

SELECT COUNT(*), COALESCE(SUM(amount), 0) INTO @n9_rows_fix, @n9_amt_fix FROM (
    SELECT 'staff' AS payee_type, u.full_name AS payee, t.name AS tournament, p.amount
         , COALESCE(p.status, 'unrecorded') AS status
    FROM Payments p
    JOIN Users u      ON u.user_id = p.staff_user_id
    JOIN Tournament t ON t.tournament_id = p.tournament_id
    WHERE COALESCE(p.status, '') <> 'paid'
    UNION ALL
    SELECT 'team', tm.team_name, t.name, p.amount, COALESCE(p.status, 'unrecorded')
    FROM Payments p
    JOIN Teams tm     ON tm.team_id = p.team_id
    JOIN Tournament t ON t.tournament_id = p.tournament_id
    WHERE COALESCE(p.status, '') <> 'paid'
) x;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N9', 'query', 'Q8 outstanding payments',
 IF(@n9_rows_fix > @n9_rows_asis, 'GAP', 'OK'),
 CONCAT('rows ', @n9_rows_asis, ' vs ', @n9_rows_fix,
        '; money owed shown ', @n9_amt_asis, ' of ', @n9_amt_fix,
        ' -- hidden: ', @n9_amt_fix - @n9_amt_asis),
 'two unrecorded debts, one staff and one team, are both absent from the report that exists to find them');


-- =====================================================================
-- N10 -- Q9 drops the best player in the game off the top-5
--
--     ROUND(SUM(pms.kills) / SUM(pms.deaths), 2)  ...  ORDER BY kd_ratio DESC
--
-- Division by zero in MySQL returns NULL rather than raising an error, so a
-- player who has never died gets kd_ratio NULL. MySQL sorts NULL last under
-- DESC, so LIMIT 5 cuts them off: the query for "highest K/D" is the one query
-- guaranteed to exclude a perfect record. v_public_player_stats got this right
-- with NULLIF; Q9, which predates it, did not.
-- =====================================================================
START TRANSACTION;
INSERT INTO Players (ign) VALUES ('null-test flawless#000');
SET @n10_p := LAST_INSERT_ID();
INSERT INTO PlayerMatchStats (player_id, match_id, kills, deaths, assists, score)
VALUES (@n10_p, 7, 40, 0, 5, 500);

-- Membership in the top 5 is counted by a conditional SUM over the derived
-- table rather than by an outer WHERE. An outer WHERE could in principle be
-- pushed down past the LIMIT by the optimiser, which would silently answer a
-- different question than the one Q9's user sees.
SELECT COALESCE(SUM(x.ign = 'null-test flawless#000'), 0) INTO @n10_asis FROM (
    SELECT pl.ign, ROUND(SUM(pms.kills) / SUM(pms.deaths), 2) AS kd_ratio
    FROM Players pl
    JOIN PlayerMatchStats pms ON pms.player_id = pl.player_id
    GROUP BY pl.player_id, pl.ign
    ORDER BY kd_ratio DESC
    LIMIT 5
) x;

SELECT COALESCE(SUM(x.ign = 'null-test flawless#000'), 0) INTO @n10_fix FROM (
    SELECT pl.ign
         , ROUND(SUM(pms.kills) / NULLIF(SUM(pms.deaths), 0), 2) AS kd_ratio
         , (COALESCE(SUM(pms.deaths), 0) = 0) AS never_died
    FROM Players pl
    JOIN PlayerMatchStats pms ON pms.player_id = pl.player_id
    GROUP BY pl.player_id, pl.ign
    ORDER BY never_died DESC, kd_ratio DESC
    LIMIT 5
) x;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N10', 'query', 'Q9 K/D ratio',
 IF(@n10_fix > @n10_asis, 'GAP', 'OK'),
 CONCAT('40 kills / 0 deaths appears in the top 5: as written ', @n10_asis,
        ', null-safe ', @n10_fix),
 'x/0 is NULL in MySQL and NULL sorts last under DESC, so LIMIT 5 removes the strongest record in the table');


-- =====================================================================
-- N11 -- Q11 hides the sponsor who delivered nothing
--
--     JOIN Deliverables d ON d.contract_id = c.contract_id
--
-- A sponsor whose contract has no Deliverables row is a dangling tuple and
-- vanishes. The business requirement this query answers is "know whether
-- sponsor deliverables were fulfilled", and the sponsor who delivered NOTHING
-- is precisely the one the report must show. Q12 gets the identical question
-- right by using correlated subqueries over Sponsors instead of a join, which
-- is why the two are worth reading side by side.
-- =====================================================================
START TRANSACTION;
INSERT INTO Sponsors (company_name, contact_name, contact_email)
VALUES ('Null Test Energy', 'No Show', 'null@test.gg');
SET @n11_s := LAST_INSERT_ID();

INSERT INTO Contracts
    (org_id, tournament_id, party_type, sponsor_id, creator_id, start_date, end_date, total_value)
VALUES (1, 1, 'sponsor', @n11_s, NULL, '2026-01-01', '2026-03-16', 7500.00);

SELECT COUNT(DISTINCT company_name) INTO @n11_asis FROM (
    SELECT s.company_name, d.status, COUNT(*) AS num_deliverables
    FROM Sponsors s
    JOIN Contracts c    ON c.sponsor_id  = s.sponsor_id AND c.party_type = 'sponsor'
    JOIN Deliverables d ON d.contract_id = c.contract_id
    GROUP BY s.sponsor_id, s.company_name, d.status
) x;

SELECT COUNT(DISTINCT company_name) INTO @n11_fix FROM (
    SELECT s.company_name
         , COALESCE(d.status, '(no deliverable recorded)') AS status
         , COUNT(d.deliverable_id) AS num_deliverables
    FROM Sponsors s
    LEFT JOIN Contracts c    ON c.sponsor_id  = s.sponsor_id AND c.party_type = 'sponsor'
    LEFT JOIN Deliverables d ON d.contract_id = c.contract_id
    GROUP BY s.sponsor_id, s.company_name, d.status
) x;

SELECT COALESCE(SUM(total_value), 0) INTO @n11_hidden
FROM Contracts c
WHERE c.party_type = 'sponsor'
  AND c.sponsor_id = @n11_s
  AND NOT EXISTS (SELECT 1 FROM Deliverables d WHERE d.contract_id = c.contract_id);
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N11', 'query', 'Q11 deliverable fulfilment',
 IF(@n11_fix > @n11_asis, 'GAP', 'OK'),
 CONCAT('sponsors reported ', @n11_asis, ' of ', @n11_fix,
        '; contract value with no deliverables at all: ', @n11_hidden),
 'the sponsor who delivered nothing is the one the fulfilment report must show, and it is the only one it cannot');


-- #####################################################################
-- #  C O N T R O L S
-- #
-- #  The other half of the audit. If every inner join on a nullable column
-- #  were converted, three of these views would break.
-- #####################################################################

-- =====================================================================
-- N12 -- v_registration_violations must KEEP its inner join
--
--     JOIN Teams tm ON tm.team_id = c.team_id      -- Competitor.team_id NULLABLE
--
-- Competitor.team_id is NULL for every solo entrant, so this inner join does
-- drop rows -- and that is the intended meaning. The rule under test ("a team
-- and its tournament must be for the same game") has no content for a
-- competitor that is not a team, and the view says so in its WHERE clause:
-- c.competitor_type = 'team', for which the CHECK guarantees team_id NOT NULL.
-- The dropped rows and the excluded rows are the same rows.
--
-- The test also shows the trap from the other side. A faithful outer rewrite
-- changes nothing, because the predicate tm.game_id <> t.game_id sits in WHERE
-- and re-inners the join. A rewrite that "fixes" that by adding
-- OR tm.game_id IS NULL invents a false violation for every solo registration.
-- =====================================================================
START TRANSACTION;
-- inject one genuine violation: competitor 1 is a Valorant team, tournament 3 is TFT
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
VALUES (1, 3, CURRENT_DATE, 91);

SELECT COUNT(*) INTO @n12_inner FROM v_registration_violations;

SELECT COUNT(*) INTO @n12_outer FROM (
    SELECT r.tournament_id
    FROM Registration r
    JOIN Tournament t   ON t.tournament_id = r.tournament_id
    JOIN Competitor c   ON c.competitor_id = r.competitor_id
    LEFT JOIN Teams tm  ON tm.team_id      = c.team_id
    WHERE c.competitor_type = 'team'
      AND tm.game_id <> t.game_id
) x;

SELECT COUNT(*) INTO @n12_naive FROM (
    SELECT r.tournament_id
    FROM Registration r
    JOIN Tournament t   ON t.tournament_id = r.tournament_id
    JOIN Competitor c   ON c.competitor_id = r.competitor_id
    LEFT JOIN Teams tm  ON tm.team_id      = c.team_id
    WHERE tm.game_id <> t.game_id OR tm.game_id IS NULL
) x;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N12', 'control', 'v_registration_violations',
 IF(@n12_inner = @n12_outer AND @n12_naive > @n12_inner, 'OK', 'FAIL'),
 CONCAT('inner ', @n12_inner, ', faithful outer ', @n12_outer,
        ', naive outer ', @n12_naive, ' (', @n12_naive - @n12_inner, ' invented)'),
 'CORRECT AS WRITTEN: the NULL team_id rows are exactly the rows the WHERE clause already excludes');


-- =====================================================================
-- N13 -- the fix must not widen the security boundary
--
-- v_my_team_payouts joins EsportsOrg to Teams on the NULLABLE
-- Teams.esports_org_id. That inner join is also CORRECT: five of the eight
-- teams have no parent org, and an unaffiliated team must not appear in any
-- org's payout report. Only the Payments join was wrong (N4). This test proves
-- the LEFT JOIN in 12_null_fixes.sql did not leak anyone else's teams -- the
-- row-level security claim from Sprint 3 has to survive the null fix.
-- =====================================================================
START TRANSACTION;
UPDATE EsportsOrg SET db_username = 'root' WHERE esports_org_id = 2;   -- QOR

SELECT COUNT(*) INTO @n13_leak
FROM v_my_team_payouts vp
JOIN Teams tm ON tm.team_name = vp.team_name
WHERE tm.esports_org_id IS NULL OR tm.esports_org_id <> 2;

SELECT COUNT(*) INTO @n13_unaffiliated FROM Teams WHERE esports_org_id IS NULL;
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N13', 'control', 'v_my_team_payouts (RLS)',
 IF(@n13_leak = 0, 'OK', 'FAIL'),
 CONCAT('foreign or unaffiliated teams visible to QOR: ', @n13_leak,
        '; teams with a NULL parent org: ', @n13_unaffiliated),
 'CORRECT AS WRITTEN: the EsportsOrg -> Teams inner join is the row filter and must stay inner');


-- =====================================================================
-- N14 -- the trap: a LEFT JOIN filtered in WHERE is an inner join again
--
-- This is the mistake that would make every fix above cosmetic. The two
-- statements differ only in where the predicate on the RIGHT-hand table sits.
-- The ON version keeps the unmatched left rows; the WHERE version tests
-- NULL = 'completed', gets UNKNOWN, and throws them away -- so the outer join
-- has been silently undone. Every rewrite in 12_null_fixes.sql keeps
-- right-table predicates in ON for this reason.
-- =====================================================================
START TRANSACTION;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, NULL, 'expense', 'null-test trap rent', 100.00, CURRENT_DATE);

SELECT COUNT(*) INTO @n14_on
FROM Transactions tr
LEFT JOIN Tournament t ON t.tournament_id = tr.tournament_id AND t.status = 'completed';

SELECT COUNT(*) INTO @n14_where
FROM Transactions tr
LEFT JOIN Tournament t ON t.tournament_id = tr.tournament_id
WHERE t.status = 'completed';
ROLLBACK;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('N14', 'control', 'LEFT JOIN ... WHERE trap',
 IF(@n14_on > @n14_where, 'OK', 'FAIL'),
 CONCAT('predicate in ON: ', @n14_on, ' rows; identical predicate in WHERE: ',
        @n14_where, ' rows'),
 'demonstrated, not asserted: moving a right-table predicate into WHERE re-inners the join');


-- =====================================================================
-- RESIDUE -- must be zero. Every test above rolls back; the database is left
-- exactly as 02_insert_data.sql left it.
-- =====================================================================
SELECT (SELECT COUNT(*) FROM Players      WHERE ign LIKE 'null-test%')
     + (SELECT COUNT(*) FROM Sponsors     WHERE company_name LIKE 'Null Test%')
     + (SELECT COUNT(*) FROM Tournament   WHERE name LIKE 'NULL-test%')
     + (SELECT COUNT(*) FROM Transactions WHERE category LIKE 'null-test%')
     + (SELECT COUNT(*) FROM Payments     WHERE amount IN (999.00, 888.00))
     + (SELECT COUNT(*) FROM Registration WHERE competitor_id = 1 AND tournament_id = 3)
     + (SELECT COUNT(*) FROM StaffMatches WHERE user_id = 12 AND match_id = 7)
     + (SELECT COUNT(*) FROM `Match`      WHERE tournament_id = 4 AND scheduled_time IS NULL)
     + (SELECT COUNT(*) FROM Users        WHERE db_username = 'root')
     + (SELECT COUNT(*) FROM Players      WHERE db_username = 'root')
     + (SELECT COUNT(*) FROM EsportsOrg   WHERE db_username = 'root')
  INTO @residue;

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('RESIDUE', 'preflight', '02_insert_data.sql', IF(@residue = 0, 'OK', 'FAIL'),
 CONCAT('stray rows or rewritten usernames left by this file: ', @residue),
 'the data and the identity mapping must be unchanged after the run');


-- =====================================================================
-- THE MEASURE -- "X of 16 views dropped rows before, 0 after"
-- Counted off the results table, not typed in.
-- =====================================================================
SELECT COUNT(DISTINCT target) INTO @views_gapped
FROM null_results WHERE kind = 'view' AND verdict = 'GAP';

SELECT COUNT(DISTINCT target) INTO @views_tested
FROM null_results WHERE kind = 'view';

SELECT COUNT(*) INTO @queries_gapped
FROM null_results WHERE kind = 'query' AND verdict = 'GAP';

INSERT INTO null_results (test, kind, target, verdict, evidence, detail) VALUES
('MEASURE', 'summary', 'Sprint 5 goal 1', IF(@views_gapped = 0, 'OK', 'GAP'),
 CONCAT(@views_gapped, ' of ', @p_views, ' views lose rows or values to NULL (',
        @views_tested, ' audited as suspect); ', @queries_gapped,
        ' of 15 queries in 03_test_queries.sql do the same'),
 'query gaps stay open by design: 03_test_queries.sql is not modified this sprint, the rewrites are Part B of 12_null_fixes.sql');


-- =====================================================================
-- VERDICT TABLE -- read this first.
-- =====================================================================
SELECT seq, test, kind, target, verdict, evidence FROM null_results ORDER BY seq;

SELECT seq, test, detail FROM null_results ORDER BY seq;

SELECT verdict, COUNT(*) AS n FROM null_results GROUP BY verdict ORDER BY verdict;

SELECT kind
     , SUM(verdict = 'GAP')  AS gaps
     , SUM(verdict = 'OK')   AS oks
     , SUM(verdict = 'FAIL') AS fails
FROM null_results GROUP BY kind ORDER BY kind;

SELECT COUNT(*) AS open_gaps
     , GROUP_CONCAT(test ORDER BY seq SEPARATOR ', ') AS gap_list
FROM null_results WHERE verdict = 'GAP' AND kind <> 'summary';

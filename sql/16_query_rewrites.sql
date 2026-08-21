-- =====================================================================
-- 16_query_rewrites.sql
--
-- Sprint 5, goal 3 follow-up: repairing Q7 by changing the QUERY, not the
-- index.
--
-- WHAT HAPPENED
-- -------------
-- 14_indexes.sql predicted Q7 would improve 18.6x once
-- idx_match_tournament_time existed. Measured: 502,451 rows examined before,
-- 502,451 after -- no improvement at all. The prediction is left as written;
-- this file explains the miss and repairs it.
--
-- The prediction assumed that
--
--     WHERE m.scheduled_time = (SELECT MAX(m2.scheduled_time)
--                               FROM `Match` m2
--                               WHERE m2.tournament_id = m.tournament_id)
--
-- would use MySQL's MIN/MAX-by-index optimisation: equality on the leading
-- column of (tournament_id, scheduled_time), MAX on the next, therefore one
-- B+-tree descent per tournament.
--
-- EXPLAIN shows the index IS chosen and IS covering ("Using index") for both
-- `m` and the subquery `m2`. The optimisation still does not fire, because it
-- is not applied inside a DEPENDENT SUBQUERY. The subquery is re-executed per
-- outer row and walks its whole range each time. The index made every walk
-- cheaper -- wall clock fell 1,443 ms to 487 ms, about 3x -- but the number of
-- entries walked never changed, which is exactly what the rows-examined metric
-- counts and why the metric reported no gain.
--
-- The defect is therefore in the SHAPE of the query, not in the choice of
-- index. No index can fix a plan that re-runs a range scan once per outer row.
-- Module 28 makes the same point in the other direction: the same answer can be
-- asked for in more than one way, and the ways are not equally expensive.
--
-- THE REWRITE
-- -----------
-- Compute "the last match of each tournament" ONCE as a grouped derived table,
-- then join to it, instead of asking the question again for every outer row.
-- 400 dependent executions collapse to one grouped pass.
--
-- Only GROUP BY, derived tables and joins are used. MySQL 8 window functions
-- (ROW_NUMBER, OVER (PARTITION BY ...)) would express this in one pass and are
-- the modern idiom, but they appear nowhere in the course material, so they are
-- deliberately not used here.
--
-- NULL SAFETY IS PRESERVED
-- ------------------------
-- Q7-B (12_null_fixes.sql) fixed a separate defect: Match.scheduled_time is
-- NULLABLE, MAX() over all-NULL returns NULL, and "scheduled_time = NULL" is
-- UNKNOWN, so a tournament whose times were never entered silently had no
-- champion. Q7-C below keeps that repair. MAX() ignores NULLs, so agg.mx is
-- NULL only when EVERY match in that tournament has a NULL time -- which is
-- precisely the case the OR arm catches. Ties are broken by MAX(match_id),
-- matching Q7-B's "match_id DESC" tie-break, so exactly one match per
-- tournament is returned either way.
--
--   Q7-A  original          dependent subquery, NOT null-safe   (03_test_queries.sql)
--   Q7-B  null-safe         dependent subquery, null-safe       (12_null_fixes.sql)
--   Q7-C  rewritten         derived table,      null-safe       (this file)
--
-- run_q7_rewrite_test.sh measures all three on the same 370,910-row database
-- with the same indexes, and checks that B and C return identical result sets.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Q7-C: champions per tournament -- null-safe AND set-based.
--
-- The derived table `lm` answers "which match_id is the final of each
-- tournament" for every tournament in one grouped pass:
--
--   inner  agg : MAX(scheduled_time) per tournament. NULL only if all NULL.
--   outer  lm  : among the matches holding that time, the highest match_id.
--                The OR arm handles the all-NULL tournament.
-- ---------------------------------------------------------------------
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

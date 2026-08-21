#!/usr/bin/env bash
# =====================================================================
# run_q7_rewrite_test.sh
#
# Sprint 5, goal 3 follow-up. Measures the three forms of Q7 against the same
# 370,910-row database with the same indexes, to show that Q7's cost lives in
# the SHAPE of the query rather than in the choice of index.
#
#   bash run_q7_rewrite_test.sh <root-password> [--rebuild]
#
# Without --rebuild the script uses the database as it stands, which is what
# run_index_tests.sh leaves behind. With --rebuild it regenerates everything
# from scratch (schema, seed, 13_bulk_data.sql, 14_indexes.sql) first, which
# takes about a minute.
#
# Method is identical to run_index_tests.sh so the numbers are comparable:
# FLUSH STATUS, run the query, read the seven Handler_read_* counters back in
# the same session. Those are a count, not an estimate, and cannot be flattered
# by the buffer pool.
#
# `local` in measure() is load-bearing -- see the comment in run_index_tests.sh.
# =====================================================================
set -u

ROOT_PW="${1:?usage: bash run_q7_rewrite_test.sh <root-password> [--rebuild]}"
REBUILD="${2:-}"
DB=design_project_370
OUT=q7_rewrite_output.txt
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cd "$(dirname "$0")"

COUNTERS="'Handler_read_first','Handler_read_key','Handler_read_last','Handler_read_next','Handler_read_prev','Handler_read_rnd','Handler_read_rnd_next'"

mysql_root() { mysql -u root -p"$ROOT_PW" "$@" 2>/dev/null; }

# --- optional rebuild -------------------------------------------------
if [ "$REBUILD" = "--rebuild" ]; then
    echo "==> rebuilding schema and seed data"
    mysql_root -e "CREATE DATABASE IF NOT EXISTS $DB;"
    for f in 01_create_tables.sql 02_insert_data.sql; do
        if ! mysql_root "$DB" < "$f" 2>"$WORK/err"; then
            echo "FAILED on $f:"; cat "$WORK/err"; exit 1
        fi
        echo "    ok  $f"
    done
    echo "==> generating bulk data (about a minute)"
    mysql_root "$DB" < 13_bulk_data.sql > /dev/null 2>"$WORK/err" \
        || { echo "FAILED on 13_bulk_data.sql:"; cat "$WORK/err"; exit 1; }
    echo "    ok  13_bulk_data.sql"
    mysql_root "$DB" < 14_indexes.sql > /dev/null 2>"$WORK/err" \
        || { echo "FAILED on 14_indexes.sql:"; cat "$WORK/err"; exit 1; }
    echo "    ok  14_indexes.sql"
fi

# --- preconditions ----------------------------------------------------
echo "==> preconditions"
ROWS=$(mysql_root -N -B "$DB" -e "SELECT COUNT(*) FROM PlayerMatchStats;")
IDX=$(mysql_root -N -B "$DB" -e "SELECT COUNT(DISTINCT index_name) FROM information_schema.statistics WHERE table_schema='$DB' AND index_name LIKE 'idx_%';")
echo "    PlayerMatchStats rows : $ROWS   (expected ~158500 -- rerun with --rebuild if 0)"
echo "    idx_* indexes present : $IDX    (expected 3)"
if [ "$ROWS" -lt 1000 ] || [ "$IDX" -lt 3 ]; then
    echo "    PRECONDITION FAILED -- rerun with:  bash run_q7_rewrite_test.sh <pw> --rebuild"
    exit 1
fi

# --- the three query forms -------------------------------------------
# Quoted heredocs: `Match` is backticked and bash would treat it as a command
# substitution inside an unquoted one.
cat > "$WORK/Q7A.sql" <<'SQL'
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
ORDER BY tournaments_won DESC, champion
SQL

cat > "$WORK/Q7B.sql" <<'SQL'
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
ORDER BY tournaments_won DESC, champion
SQL

cat > "$WORK/Q7C.sql" <<'SQL'
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
ORDER BY tournaments_won DESC, champion
SQL

# --- measurement ------------------------------------------------------
measure() {
    local qid="$1" q t0 t1
    q="$(cat "$WORK/$qid.sql")"

    printf 'EXPLAIN %s;\n' "$q" > "$WORK/explain.sql"
    mysql_root -t "$DB" < "$WORK/explain.sql" > "$WORK/$qid.explain" 2>&1

    printf 'EXPLAIN ANALYZE %s;\n' "$q" > "$WORK/analyze.sql"
    mysql_root -t "$DB" < "$WORK/analyze.sql" > "$WORK/$qid.analyze" 2>&1

    printf 'FLUSH STATUS;\n%s;\nSELECT %s;\nSHOW SESSION STATUS WHERE Variable_name IN (%s);\n' \
        "$q" "'---COUNTERS---'" "$COUNTERS" > "$WORK/run.sql"

    t0=$(date +%s%N)
    mysql_root -N -B "$DB" < "$WORK/run.sql" > "$WORK/$qid.raw" 2>&1
    t1=$(date +%s%N)

    echo $(( (t1 - t0) / 1000000 )) > "$WORK/$qid.ms"
    awk '/---COUNTERS---/ { seen = 1; next } seen' "$WORK/$qid.raw" > "$WORK/$qid.handlers"

    # result set, for the equivalence check
    printf '%s;\n' "$q" > "$WORK/res.sql"
    mysql_root -N -B "$DB" < "$WORK/res.sql" > "$WORK/$qid.rows" 2>&1
}

rows_examined() {
    awk -F'\t' '$1 ~ /^Handler_read_/ { s += $2 } END { printf "%d", s + 0 }' "$1"
}

echo "==> measuring Q7-A (original), Q7-B (null-safe), Q7-C (rewritten)"
for qid in Q7A Q7B Q7C; do
    measure "$qid"
    echo "    $qid  rows examined = $(rows_examined "$WORK/$qid.handlers")  wall = $(cat "$WORK/$qid.ms") ms"
done

A=$(rows_examined "$WORK/Q7A.handlers")
B=$(rows_examined "$WORK/Q7B.handlers")
C=$(rows_examined "$WORK/Q7C.handlers")
MA=$(cat "$WORK/Q7A.ms"); MB=$(cat "$WORK/Q7B.ms"); MC=$(cat "$WORK/Q7C.ms")

# --- equivalence: B and C must agree ---------------------------------
if diff -q "$WORK/Q7B.rows" "$WORK/Q7C.rows" > /dev/null 2>&1; then
    EQUIV="IDENTICAL"
else
    EQUIV="DIFFERENT -- investigate"
fi
BROWS=$(wc -l < "$WORK/Q7B.rows")

ratio() { awk -v a="$1" -v b="$2" 'BEGIN { if (b == 0) printf "n/a"; else printf "%.2fx", a / b }'; }

{
echo "====================================================================="
echo " Q7 REWRITE -- repairing a query by changing its SHAPE, not its index"
echo " MySQL 8.0.46, $ROWS PlayerMatchStats rows, $IDX idx_* indexes present"
echo "====================================================================="
echo
echo "  Q7-A  original    dependent subquery, not null-safe   03_test_queries.sql"
echo "  Q7-B  null-safe   dependent subquery, null-safe       12_null_fixes.sql"
echo "  Q7-C  rewritten   derived table,      null-safe       16_query_rewrites.sql"
echo
printf '%-8s %14s %10s %12s\n' "form" "rows examined" "wall" "vs Q7-A"
printf '%-8s %14s %10s %12s\n' "----" "-------------" "----" "-------"
printf '%-8s %14s %10s %12s\n' "Q7-A" "$A" "${MA}ms" "-"
printf '%-8s %14s %10s %12s\n' "Q7-B" "$B" "${MB}ms" "$(ratio "$A" "$B")"
printf '%-8s %14s %10s %12s\n' "Q7-C" "$C" "${MC}ms" "$(ratio "$A" "$C")"
echo
echo "  equivalence Q7-B vs Q7-C : $EQUIV  ($BROWS rows each)"
echo
echo "  The index is unchanged across all three. Any difference is attributable"
echo "  to query shape alone."
echo
for qid in Q7A Q7B Q7C; do
    echo "---------------------------------------------------------------------"
    echo "# $qid"
    echo "---------------------------------------------------------------------"
    cat "$WORK/$qid.sql"
    echo
    echo "--- EXPLAIN ---------------------------------------------------------"
    cat "$WORK/$qid.explain"
    echo
    echo "--- EXPLAIN ANALYZE -------------------------------------------------"
    cat "$WORK/$qid.analyze"
    echo
    echo "--- Handler_read_* counters -----------------------------------------"
    cat "$WORK/$qid.handlers"
    echo
done
} > "$OUT"

echo "==> wrote $OUT"
echo
echo "---------------------------------------------------------------------"
printf '%-8s %14s %10s %12s\n' "form" "rows examined" "wall" "vs Q7-A"
printf '%-8s %14s %10s %12s\n' "Q7-A" "$A" "${MA}ms" "-"
printf '%-8s %14s %10s %12s\n' "Q7-B" "$B" "${MB}ms" "$(ratio "$A" "$B")"
printf '%-8s %14s %10s %12s\n' "Q7-C" "$C" "${MC}ms" "$(ratio "$A" "$C")"
echo "  equivalence Q7-B vs Q7-C : $EQUIV  ($BROWS rows each)"
echo "---------------------------------------------------------------------"

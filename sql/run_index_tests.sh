#!/usr/bin/env bash
# =====================================================================
# run_index_tests.sh
#
# Sprint 5, goal 3. Rebuilds the database, grows it past 100,000 rows,
# measures the three chosen queries with no new index, applies
# 14_indexes.sql, measures the identical three again, and writes a
# before/after comparison to index_test_output.txt.
#
#   bash run_index_tests.sh <root-password>
#
# Modelled on run_acid_tests.sh: same argument handling, same mysql_root
# helper, same assumption that `mysql` is on PATH, same discipline of
# reading numbers back out of the server instead of asserting them.
#
# WHAT IT MEASURES, AND WHY THREE DIFFERENT WAYS
#
#   1. EXPLAIN            the plan the optimiser chose, and its ROW ESTIMATE.
#                         This is the estimate, not the truth. It is recorded
#                         because the access method named in the `type` and
#                         `Extra` columns ("ref", "range", "Using index") is
#                         what tells us whether the predicted plan is the one
#                         that ran.
#
#   2. EXPLAIN ANALYZE    actual rows and, crucially, LOOPS. A dependent
#                         subquery shows as "(actual rows=40 loops=11892)",
#                         and 40*11892 is the number 14_indexes.sql predicted.
#                         Also gives server-side timing.
#
#   3. Handler_read_*     the authority. These session counters are the
#                         server's own count of how many rows the storage
#                         engine handed to the executor. FLUSH STATUS zeroes
#                         them, the query runs, SHOW SESSION STATUS reads them
#                         back. Unlike EXPLAIN's `rows` column this is not an
#                         estimate, and unlike wall-clock it is not affected
#                         by the buffer pool. It is the right thing to compare
#                         against a prediction made in the external memory
#                         model, and it is what "rows examined" means.
#
#   Wall-clock is recorded too, but as the least trustworthy number: the
#   external memory model charges for every block access, while the buffer
#   pool serves most of them from RAM. Where the model and the clock disagree,
#   that gap is the finding, not an error.
#
# All three measurements happen in ONE mysql invocation per query per phase,
# because Handler_read_* are SESSION counters and a new client connection
# would reset them.
#
# The three queries are copied verbatim out of 03_test_queries.sql. That file
# is not modified and not sourced, because sourcing it would run all 15
# queries and pollute the counters.
# =====================================================================
set -u

ROOT_PW="${1:?usage: bash run_index_tests.sh <root-password>}"
DB=design_project_370
OUT=index_test_output.txt

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cd "$(dirname "$0")"

mysql_root() { mysql -u root -p"$ROOT_PW" "$@"; }

# The status counters that together make up "rows examined", plus the sort
# and temp-table counters, which are how we check the "avoids a sort" claims.
COUNTERS="'Handler_read_first','Handler_read_key','Handler_read_last'
        ,'Handler_read_next','Handler_read_prev','Handler_read_rnd'
        ,'Handler_read_rnd_next','Sort_merge_passes','Sort_range'
        ,'Sort_rows','Sort_scan','Created_tmp_tables','Created_tmp_disk_tables'
        ,'Select_scan','Select_full_join'"


# =====================================================================
# THE THREE QUERIES, VERBATIM FROM 03_test_queries.sql
# =====================================================================

cat > "$WORK/Q1.sql" <<'SQL'
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
ORDER BY profit DESC
SQL

cat > "$WORK/Q6.sql" <<'SQL'
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
LIMIT 5
SQL

cat > "$WORK/Q7.sql" <<'SQL'
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


# =====================================================================
# PREDICTIONS, COMMITTED IN 14_indexes.sql BEFORE ANY OF THIS RAN
#
# These literals are transcribed from PARTs 3, 4 and 5 of 14_indexes.sql.
# They are the whole point of the exercise: if they are edited after a run,
# the exercise is worthless.
# =====================================================================
#              predicted I/O      predicted rows examined
#              before   after     before    after      ratio
PRED_Q1="84808   4808    80400    40400    2.00"
PRED_Q6="717353  558803  333265   333265   1.00"
PRED_Q7="527864  28292   490180   26392    18.57"


# =====================================================================
# BUILD
# =====================================================================

echo "==> rebuilding schema and loading seed data"
mysql_root -e "CREATE DATABASE IF NOT EXISTS $DB;" 2>/dev/null
for f in 01_create_tables.sql 02_insert_data.sql; do
    if ! mysql_root "$DB" < "$f" 2>"$WORK/err"; then
        echo "FAILED on $f:"; cat "$WORK/err"; exit 1
    fi
    echo "    ok  $f"
done

# 13 must apply cleanly. FOREIGN_KEY_CHECKS is left on inside it, so an error
# here is a real failure of the generator, not an expected result.
echo "==> generating bulk data (this takes a minute; ~370,000 rows)"
if ! mysql_root -t "$DB" < 13_bulk_data.sql > "$WORK/13.out" 2>"$WORK/err"; then
    echo "FAILED on 13_bulk_data.sql:"; cat "$WORK/err"; exit 1
fi
echo "    ok  13_bulk_data.sql"

# Without this the optimiser is costing plans against stale cardinalities and
# every EXPLAIN below is measuring the wrong thing.
echo "==> ANALYZE TABLE on every table"
TABLES=$(mysql_root -N -B "$DB" -e \
    "SELECT GROUP_CONCAT(CONCAT('\`', TABLE_NAME, '\`'))
       FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = '$DB' AND TABLE_TYPE = 'BASE TABLE';")
mysql_root -t "$DB" -e "ANALYZE TABLE $TABLES;" > "$WORK/analyze_before.out" 2>&1
echo "    ok  analyzed"


# =====================================================================
# MEASUREMENT
#
#   measure <phase> <qid>
#
# Runs the query three ways in one session and leaves four files behind:
#   $WORK/<qid>.<phase>.explain    plan + row estimate
#   $WORK/<qid>.<phase>.analyze    EXPLAIN ANALYZE tree, with loops
#   $WORK/<qid>.<phase>.handlers   Variable_name<TAB>Value
#   $WORK/<qid>.<phase>.ms         wall clock, milliseconds
# =====================================================================
# Every statement is built with printf and fed to mysql on STDIN, never via
# -e "...". Q6 and Q7 contain `Match` in backticks, and bash would run that as
# a command substitution inside any double-quoted string or unquoted heredoc.
measure() {
    # `local` is load-bearing: without it, q is global and clobbers the
    # `for q in Q1 Q6 Q7` loop variable with the query text on the first call,
    # so every later filename becomes the whole query ("File name too long").
    local phase="$1" qid="$2" q t0 t1
    q="$(cat "$WORK/$qid.sql")"

    printf 'EXPLAIN %s;\n' "$q" > "$WORK/explain.sql"
    mysql_root -t "$DB" < "$WORK/explain.sql" \
        > "$WORK/$qid.$phase.explain" 2>&1

    printf 'EXPLAIN ANALYZE %s;\n' "$q" > "$WORK/analyze.sql"
    mysql_root -t "$DB" < "$WORK/analyze.sql" \
        > "$WORK/$qid.$phase.analyze" 2>&1

    # One session: zero the counters, run the query, read the counters back.
    # -N -B keeps the output machine-parseable; the marker separates the
    # query's own result rows from the status rows.
    printf 'FLUSH STATUS;\n%s;\nSELECT %s;\nSHOW SESSION STATUS WHERE Variable_name IN (%s);\n' \
        "$q" "'---COUNTERS---'" "$COUNTERS" > "$WORK/run.sql"

    t0=$(date +%s%N)
    mysql_root -N -B "$DB" < "$WORK/run.sql" > "$WORK/raw.out" 2>&1
    t1=$(date +%s%N)

    echo $(( (t1 - t0) / 1000000 )) > "$WORK/$qid.$phase.ms"
    awk '/---COUNTERS---/ { seen = 1; next } seen' "$WORK/raw.out" \
        > "$WORK/$qid.$phase.handlers"
}

# Sum the seven Handler_read_* counters. That sum is "rows examined": every
# row the storage engine handed up, however it was reached.
rows_examined() {
    awk -F'\t' '$1 ~ /^Handler_read_/ { s += $2 } END { printf "%d", s + 0 }' "$1"
}

counter() {
    awk -F'\t' -v want="$2" '$1 == want { print $2 }' "$1"
}


echo "==> phase BEFORE: measuring Q1, Q6, Q7 with no new index"
for q in Q1 Q6 Q7; do
    measure before "$q"
    echo "    $q  rows examined = $(rows_examined "$WORK/$q.before.handlers")" \
         " wall = $(cat "$WORK/$q.before.ms") ms"
done

mysql_root -t "$DB" -e "
    SELECT TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX, COLUMN_NAME, NON_UNIQUE
      FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = '$DB'
     ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;" \
    > "$WORK/indexes_before.out" 2>&1

echo "==> applying 14_indexes.sql"
if ! mysql_root -t "$DB" < 14_indexes.sql > "$WORK/14.out" 2>"$WORK/err"; then
    echo "FAILED on 14_indexes.sql:"; cat "$WORK/err"; exit 1
fi
echo "    ok  14_indexes.sql"

# Re-analyze: a new index has no statistics until it is analyzed, and the
# optimiser will not choose an index it cannot cost.
mysql_root -t "$DB" -e "ANALYZE TABLE $TABLES;" > "$WORK/analyze_after.out" 2>&1

echo "==> phase AFTER: measuring the identical three queries"
for q in Q1 Q6 Q7; do
    measure after "$q"
    echo "    $q  rows examined = $(rows_examined "$WORK/$q.after.handlers")" \
         " wall = $(cat "$WORK/$q.after.ms") ms"
done

mysql_root -t "$DB" -e "
    SELECT TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX, COLUMN_NAME, NON_UNIQUE
      FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = '$DB'
     ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;" \
    > "$WORK/indexes_after.out" 2>&1


# =====================================================================
# THE COMPARISON TABLE
# =====================================================================

# verdict <qid> <predicted-ratio>
#
# PASS RULE, stated before the run: a prediction HOLDS if the measured
# before/after ratio is within a factor of two of the predicted ratio, i.e.
#     predicted/2  <=  measured  <=  predicted*2
# A factor of two is the right tolerance and not a generous one: the external
# memory model explicitly excludes caching ("no consideration for whether
# accesses are contiguous or random"), so it cannot be expected to predict a
# ratio to the percent. What it must get right is the ORDER of the effect --
# which is what a factor-of-two band tests.
verdict() {
    qid="$1"; pred="$2"
    b=$(rows_examined "$WORK/$qid.before.handlers")
    a=$(rows_examined "$WORK/$qid.after.handlers")
    awk -v b="$b" -v a="$a" -v p="$pred" 'BEGIN {
        if (a == 0) { print "n/a"; exit }
        r = b / a
        if (r >= p / 2 && r <= p * 2) printf "HELD"
        else                          printf "MISSED"
    }'
}

halved() {
    qid="$1"
    b=$(rows_examined "$WORK/$qid.before.handlers")
    a=$(rows_examined "$WORK/$qid.after.handlers")
    awk -v b="$b" -v a="$a" 'BEGIN {
        if (a == 0)      { print "n/a" }
        else if (b >= 2*a) { print "YES" }
        else               { print "no" }
    }'
}

row_for() {
    qid="$1"; shift
    set -- $1
    pio_b="$1"; pio_a="$2"; pre_b="$3"; pre_a="$4"; prat="$5"
    b=$(rows_examined "$WORK/$qid.before.handlers")
    a=$(rows_examined "$WORK/$qid.after.handlers")
    mb=$(cat "$WORK/$qid.before.ms")
    ma=$(cat "$WORK/$qid.after.ms")
    ratio=$(awk -v b="$b" -v a="$a" 'BEGIN { if (a) printf "%.2f", b/a; else printf "n/a" }')
    printf '| %-3s | %10s | %9s | %10s | %10s | %6s | %10s | %10s | %6s | %6s | %-6s | %-3s |\n' \
        "$qid" "$pio_b" "$pio_a" "$pre_b" "$pre_a" "$prat" \
        "$b" "$a" "$ratio" "${mb}ms" "${ma}ms" "$(verdict "$qid" "$prat")"
}

{
echo "====================================================================="
echo " INDEX TEST TRANSCRIPT"
echo " Generated by run_index_tests.sh against MySQL $(mysql_root -N -B -e 'SELECT VERSION();' 2>/dev/null)"
echo " $(date)"
echo
echo " Sprint 5, goal 3: add indexes and measure them."
echo
echo " The predicted columns below were committed in 14_indexes.sql BEFORE"
echo " this script was ever run. They are derived in the external memory"
echo " model of CSC370-29/30/33: 4KB blocks, cost = blocks read and written,"
echo " B+-tree lookup = log_M(N) with no cached-root discount, fan-out from"
echo " key*d + 8(d+1) <= 4096, sizes from T(R)/V(R,x)."
echo
echo " ROWS EXAMINED is the sum of the seven Handler_read_* session counters,"
echo " read out of the server after FLUSH STATUS. It is a count, not an"
echo " estimate, and the buffer pool cannot flatter it."
echo "====================================================================="
echo
echo
echo "====================================================================="
echo " SECTION 1 -- ROW COUNTS AFTER 13_bulk_data.sql"
echo "====================================================================="
cat "$WORK/13.out"
echo
echo
echo "====================================================================="
echo " SECTION 2 -- INDEXES THAT ALREADY EXISTED BEFORE 14_indexes.sql"
echo
echo " The README says 01_create_tables.sql 'declares 0 indexes'. True, and"
echo " it does not follow that the database has none. Every PRIMARY KEY and"
echo " UNIQUE creates one, and InnoDB silently creates an index on the child"
echo " columns of every FOREIGN KEY that does not already have one. The list"
echo " below is the evidence, and it is why the BEFORE baselines in this run"
echo " are index lookups rather than table scans."
echo "====================================================================="
cat "$WORK/indexes_before.out"
echo
echo
echo "====================================================================="
echo " SECTION 3 -- THE COMPARISON"
echo "====================================================================="
echo
echo "| Q   | pred I/O   | pred I/O  | pred rows  | pred rows  | pred   | actual     | actual     | actual | wall   | wall   | held?"
echo "|     | before     | after     | ex. before | ex. after  | ratio  | ex. before | ex. after  | ratio  | before | after  |"
echo "|-----|------------|-----------|------------|------------|--------|------------|------------|--------|--------|--------|------|"
row_for Q1 "$PRED_Q1"
row_for Q6 "$PRED_Q6"
row_for Q7 "$PRED_Q7"
echo
echo "PASS RULE: a prediction HELD if the measured before/after ratio is"
echo "within a factor of two of the predicted ratio. The external memory"
echo "model excludes caching by construction, so it is accountable for the"
echo "order of the effect, not for the last percent."
echo
echo "---------------------------------------------------------------------"
echo " THE MEASURE the README set: 'all 3 predictions correct, and EXPLAIN"
echo " shows half the rows examined on 2 of 3.'"
echo "---------------------------------------------------------------------"
printf '  Q1  rows examined at least halved: %s\n' "$(halved Q1)"
printf '  Q6  rows examined at least halved: %s\n' "$(halved Q6)"
printf '  Q7  rows examined at least halved: %s\n' "$(halved Q7)"
echo
echo "  Q6 was predicted NOT to halve, in advance, in PART 5 of"
echo "  14_indexes.sql. Q6 has no WHERE clause and every one of its joins is"
echo "  a primary-key equality with fan-out 1, so neither T(R)/V(R,x) nor"
echo "  the join rule has anything to remove. An index changes how wide a"
echo "  block is, never how many tuples an unrestricted aggregate must see."
echo
echo
echo "====================================================================="
echo " SECTION 4 -- SORTING AND TEMPORARY TABLES"
echo
echo " Sort_rows / Sort_scan / Sort_merge_passes and the tmp-table counters."
echo " These are how the 'avoids a sort' claims are checked; a covering index"
echo " that removed a filesort shows up here and nowhere else."
echo "====================================================================="
for q in Q1 Q6 Q7; do
    echo
    echo "-- $q ---------------------------------------------------------------"
    printf '%-26s %14s %14s\n' "counter" "before" "after"
    for c in Sort_rows Sort_scan Sort_range Sort_merge_passes \
             Created_tmp_tables Created_tmp_disk_tables \
             Select_scan Select_full_join \
             Handler_read_key Handler_read_next Handler_read_rnd_next \
             Handler_read_first Handler_read_rnd; do
        printf '%-26s %14s %14s\n' "$c" \
            "$(counter "$WORK/$q.before.handlers" "$c")" \
            "$(counter "$WORK/$q.after.handlers" "$c")"
    done
done
echo
echo
echo "====================================================================="
echo " SECTION 5 -- PLANS, BEFORE AND AFTER"
echo "====================================================================="
for q in Q1 Q6 Q7; do
    echo
    echo "#####################################################################"
    echo "# $q"
    echo "#####################################################################"
    echo
    echo "--- EXPLAIN, before ------------------------------------------------"
    cat "$WORK/$q.before.explain"
    echo
    echo "--- EXPLAIN, after -------------------------------------------------"
    cat "$WORK/$q.after.explain"
    echo
    echo "--- EXPLAIN ANALYZE, before ----------------------------------------"
    echo "    (read the loops= figures: a dependent subquery's rows examined"
    echo "     is actual rows x loops, which is the product 14_indexes.sql"
    echo "     predicted)"
    cat "$WORK/$q.before.analyze"
    echo
    echo "--- EXPLAIN ANALYZE, after -----------------------------------------"
    cat "$WORK/$q.after.analyze"
done
echo
echo
echo "====================================================================="
echo " SECTION 6 -- INDEXES AFTER 14_indexes.sql"
echo "====================================================================="
cat "$WORK/indexes_after.out"
echo
cat "$WORK/14.out"
} > "$OUT" 2>&1

echo "==> wrote $OUT"
echo

# Echo the comparison to the terminal as well, same numbers, read back from
# the same files -- never retyped.
echo "--------------------------------------------------------------------"
echo " ROWS EXAMINED (sum of Handler_read_*), before -> after"
echo "--------------------------------------------------------------------"
for q in Q1 Q6 Q7; do
    b=$(rows_examined "$WORK/$q.before.handlers")
    a=$(rows_examined "$WORK/$q.after.handlers")
    printf '  %-3s %12s -> %-12s  factor %-8s halved: %-4s\n' \
        "$q" "$b" "$a" \
        "$(awk -v b="$b" -v a="$a" 'BEGIN { if (a) printf "%.2f", b/a; else printf "n/a" }')" \
        "$(halved "$q")"
done
echo
echo "==> full transcript, plans and per-counter detail are in $OUT"

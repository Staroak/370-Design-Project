#!/usr/bin/env bash
# =====================================================================
# run_isolation_tests.sh
#
# Drives the two-session tests from 09_isolation_tests_a.sql / _b.sql so the
# interleaving is reproducible and the transcript is captured.
#
#   bash run_isolation_tests.sh <root-password>
#
# HOW THE TWO SESSIONS ARE SYNCHRONISED
# Both scripts are generated with the SAME epoch stamped into @t0, then run
# concurrently. Each step waits until an absolute offset from that anchor:
#
#     SELECT SLEEP(GREATEST(0, <t> - (UNIX_TIMESTAMP(NOW(3)) - @t0)));
#
# Offsets are absolute, not cumulative, so a step that blocks on a lock does
# not push everything after it out of alignment. Named pipes were the obvious
# approach and do not work here: Git Bash mkfifo creates an MSYS-emulated FIFO
# that the native mysql.exe cannot read.
#
# Running the two .sql files by hand in two terminals does the same thing and
# is the better demo for the sprint video. This script exists so the evidence
# lands in a file the same way 08 does.
#
# ERROR 1205 (lock wait timeout), 1213 (deadlock) and 1644 (our own SIGNAL)
# are EXPECTED RESULTS here.
# =====================================================================
set -u

ROOT_PW="${1:?usage: bash run_isolation_tests.sh <root-password>}"
DB=design_project_370
OUT=isolation_test_output.txt
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cd "$(dirname "$0")"

mysql_root() { mysql -u root -p"$ROOT_PW" "$@"; }

echo "==> resetting data (01, 02, 04, 05, 07)"
for f in 01_create_tables.sql 02_insert_data.sql 04_views.sql 05_roles_and_grants.sql 07_transactions.sql; do
    if ! mysql_root "$DB" < "$f" > /dev/null 2>"$WORK/err"; then
        echo "FAILED on $f:"; cat "$WORK/err"; exit 1
    fi
done
echo "    ok"

mysql_root "$DB" -e "
DROP TABLE IF EXISTS isolation_results;
CREATE TABLE isolation_results (
    seq      INT          NOT NULL AUTO_INCREMENT
  , test     VARCHAR(12)  NOT NULL
  , property CHAR(1)      NOT NULL
  , verdict  VARCHAR(8)   NOT NULL
  , evidence VARCHAR(200)
  , detail   VARCHAR(255)
  , PRIMARY KEY (seq)
);" 2>/dev/null

# ---------------------------------------------------------------- SESSION A
cat > "$WORK/a.tmpl" <<'ASQL'
SET @t0 = __T0__;

-- ========== A3  session A only holds the lock ==========
SELECT SLEEP(GREATEST(0, 0 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a3_start;
START TRANSACTION;
UPDATE Tournament SET status = 'in_progress' WHERE tournament_id = 1;

SELECT SLEEP(GREATEST(0, 15 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a3_end;
ROLLBACK;

-- ========== A4  deadlock: A takes Tournament then Payments ==========
SELECT SLEEP(GREATEST(0, 18 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a4_1;
START TRANSACTION;
UPDATE Tournament SET status = 'completed' WHERE tournament_id = 2;

SELECT SLEEP(GREATEST(0, 24 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a4_2;
UPDATE Payments SET status = 'paid' WHERE payment_id = 3;

SELECT SLEEP(GREATEST(0, 34 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a4_3;
ROLLBACK;

-- ========== I1  A writes a big expense and never commits ==========
SELECT SLEEP(GREATEST(0, 37 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i1_1;
START TRANSACTION;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, 1, 'expense', 'production', 50000.00, CURRENT_DATE);

SELECT SLEEP(GREATEST(0, 44 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i1_2;
ROLLBACK;

-- ========== I2  lost update ==========
SELECT SLEEP(GREATEST(0, 47 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i2_1;
START TRANSACTION;
SELECT click_count INTO @a2 FROM Deliverables WHERE deliverable_id = 5;

SELECT SLEEP(GREATEST(0, 53 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i2_2;
UPDATE Deliverables SET click_count = @a2 + 1 WHERE deliverable_id = 5;
COMMIT;

-- ========== I3-RC  A transfers while B is mid-transaction ==========
SELECT SLEEP(GREATEST(0, 65 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rc;
START TRANSACTION;
UPDATE Transactions SET amount = amount - 1000 WHERE transaction_id = 1;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, 1, 'expense', 'production', 1000.00, CURRENT_DATE);
COMMIT;

SELECT SLEEP(GREATEST(0, 73 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rc_reset;
DELETE FROM Transactions
WHERE tournament_id = 1 AND type = 'expense' AND category = 'production'
  AND amount = 1000.00;
UPDATE Transactions SET amount = 8000.00 WHERE transaction_id = 1;

-- ========== I3-RR  same schedule at the REPEATABLE READ default ==========
SELECT SLEEP(GREATEST(0, 79 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rr;
START TRANSACTION;
UPDATE Transactions SET amount = amount - 1000 WHERE transaction_id = 1;
COMMIT;

SELECT SLEEP(GREATEST(0, 87 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rr_reset;
UPDATE Transactions SET amount = 8000.00 WHERE transaction_id = 1;

-- ========== I4a  write skew, prize pool ==========
-- Leave exactly 1000 of headroom in tournament 2 (3000 pool, 3000 paid).
SELECT SLEEP(GREATEST(0, 90 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4a_setup;
UPDATE Payments SET amount = 1000.00 WHERE payment_id = 3;

SELECT SLEEP(GREATEST(0, 92 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4a_1;
START TRANSACTION;
SELECT (SELECT prize_pool FROM Tournament WHERE tournament_id = 2)
     - COALESCE(SUM(amount), 0) INTO @ha
FROM Payments WHERE tournament_id = 2 AND payee_type = 'team';

SELECT SLEEP(GREATEST(0, 98 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4a_2;
INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('team', NULL, 1, 2, 1000.00, 'paid', CURRENT_DATE);
COMMIT;
SELECT @ha INTO @ha;
INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I4a-A', 'I', 'OK', CONCAT('headroom seen by A: ', @ha), 'A half of the schedule; the verdict is recorded by B');

-- ========== I4b  write skew, player on two teams ==========
SELECT SLEEP(GREATEST(0, 107 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4b_1;
START TRANSACTION;
SELECT COUNT(*) INTO @ra FROM Roster WHERE player_id = 47 AND leave_date IS NULL;

SELECT SLEEP(GREATEST(0, 113 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4b_2;
INSERT INTO Roster (player_id, team_id, join_date, leave_date, salary, jersey_number)
VALUES (47, 5, CURRENT_DATE, NULL, 900.00, 10);
COMMIT;

-- ========== I4c  write skew, duplicate seed ==========
SELECT SLEEP(GREATEST(0, 122 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4c_1;
START TRANSACTION;
SELECT COALESCE(MAX(seed), 0) + 1 INTO @sa FROM Registration WHERE tournament_id = 2;

SELECT SLEEP(GREATEST(0, 128 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4c_2;
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
VALUES (5, 2, CURRENT_DATE, @sa);
COMMIT;

-- ========== I4-FIX  both sessions call the procedure at the same instant ====
SELECT SLEEP(GREATEST(0, 137 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4fix;
CALL sp_register_team(5, 2, 5);

-- ========== I5  write skew across tables ==========
SELECT SLEEP(GREATEST(0, 145 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i5_1;
START TRANSACTION;
SELECT COUNT(*) INTO @ma
FROM Membership WHERE user_id = 10 AND org_id = 1 AND left_date IS NULL;

SELECT SLEEP(GREATEST(0, 151 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i5_2;
INSERT INTO StaffAssignments (user_id, tournament_id, staff_role, pay_amount)
VALUES (10, 3, 'caster', 500.00);
COMMIT;

SELECT SLEEP(GREATEST(0, 155 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i5_3;
SELECT COUNT(*) INTO @i5
FROM StaffAssignments sa
JOIN Tournament t ON t.tournament_id = sa.tournament_id
LEFT JOIN Membership mb
       ON mb.user_id = sa.user_id AND mb.org_id = t.org_id AND mb.left_date IS NULL
WHERE sa.user_id = 10 AND sa.tournament_id = 3 AND mb.user_id IS NULL;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I5', 'I', IF(@i5 > 0, 'GAP', 'OK'),
 CONCAT('active membership seen by A: ', @ma, ' -- staff rows with no active membership: ', @i5),
 'A validated Membership while B revoked it; different tables, so nothing collided and nothing was detected');

DELETE FROM StaffAssignments WHERE user_id = 10 AND tournament_id = 3;
UPDATE Membership SET left_date = NULL WHERE user_id = 10 AND org_id = 1;

-- ========== residue ==========
SELECT SLEEP(GREATEST(0, 160 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _residue;
SELECT ABS((SELECT click_count FROM Deliverables WHERE deliverable_id = 5) - 3200)
     + ABS((SELECT amount FROM Transactions WHERE transaction_id = 1) - 8000)
     + ABS((SELECT amount FROM Payments WHERE payment_id = 3) - 2000)
     + (SELECT COUNT(*) FROM Roster WHERE player_id = 47)
     + (SELECT COUNT(*) FROM Registration WHERE tournament_id = 2 AND seed = 5)
     + (SELECT COUNT(*) FROM StaffAssignments WHERE user_id = 10 AND tournament_id = 3)
     + (SELECT COUNT(*) FROM Membership WHERE user_id = 10 AND org_id = 1 AND left_date IS NOT NULL)
     -- 02_insert_data.sql already contains a legitimate 2000.00 'production'
     -- expense, so only the injected 50000 and 1000 rows count as drift.
     + (SELECT COUNT(*) FROM Transactions WHERE category = 'production' AND amount <> 2000.00)
  INTO @res;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I-RESIDUE', 'P', IF(@res = 0, 'OK', 'FAIL'),
 CONCAT('drift from the seeded state: ', @res),
 'the run must leave the data exactly as 02_insert_data.sql left it');
ASQL

# ---------------------------------------------------------------- SESSION B
cat > "$WORK/b.tmpl" <<'BSQL'
SET @t0 = __T0__;

-- ========== A3  B does the interesting half ==========
-- The first INSERT deliberately targets tournament 2. An FK check takes a
-- shared lock on the parent row, so pointing it at tournament 1 would block on
-- A's lock and the INSERT would never succeed -- the test needs it to succeed.
SELECT SLEEP(GREATEST(0, 4 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a3_1;
SET SESSION innodb_lock_wait_timeout = 3;
START TRANSACTION;
INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('staff', 12, NULL, 2, 400.00, 'pending', NULL);
UPDATE Tournament SET prize_pool = 6000.00 WHERE tournament_id = 1;

-- MySQL rolled back only the UPDATE. The transaction is still open and still
-- holds the INSERT, so a script that ignores the error commits anyway.
SELECT SLEEP(GREATEST(0, 12 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a3_2;
COMMIT;
SELECT COUNT(*) INTO @a3
FROM Payments WHERE tournament_id = 2 AND staff_user_id = 12 AND amount = 400.00;
SELECT prize_pool INTO @a3pool FROM Tournament WHERE tournament_id = 1;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('A3', 'A', IF(@a3 > 0, 'GAP', 'OK'),
 CONCAT('payments surviving the timed-out transaction: ', @a3, ', pool still ', @a3pool),
 'ERROR 1205 rolled back only the failing statement; the INSERT committed without the pool change that justified it');

DELETE FROM Payments
WHERE tournament_id = 2 AND staff_user_id = 12 AND amount = 400.00 AND status = 'pending';
SET SESSION innodb_lock_wait_timeout = DEFAULT;

-- ========== A4  deadlock: B takes Payments then Tournament ==========
SELECT SLEEP(GREATEST(0, 21 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a4_1;
START TRANSACTION;
UPDATE Payments SET status = 'paid' WHERE payment_id = 3;

SELECT SLEEP(GREATEST(0, 27 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a4_2;
UPDATE Tournament SET status = 'completed' WHERE tournament_id = 2;

SELECT SLEEP(GREATEST(0, 34 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _a4_3;
ROLLBACK;

-- ========== I1  dirty read ==========
-- DELIBERATE RELAXATION of a session setting, not a schema defect. Reset below.
SELECT SLEEP(GREATEST(0, 40 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i1;
SET SESSION transaction_isolation = 'READ-UNCOMMITTED';
START TRANSACTION;
SELECT COALESCE(SUM(amount), 0) INTO @i1
FROM Transactions WHERE tournament_id = 1 AND type = 'expense';
COMMIT;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I1', 'I', IF(@i1 > 40000, 'GAP', 'OK'),
 CONCAT('expense total seen by B: ', @i1, ' (true total is 8200)'),
 'READ UNCOMMITTED let B report a loss from a row A never committed -- demonstration, not a schema defect');

SET SESSION transaction_isolation = DEFAULT;

-- ========== I2  lost update ==========
SELECT SLEEP(GREATEST(0, 50 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i2_1;
START TRANSACTION;
SELECT click_count INTO @b2 FROM Deliverables WHERE deliverable_id = 5;

SELECT SLEEP(GREATEST(0, 56 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i2_2;
UPDATE Deliverables SET click_count = @b2 + 1 WHERE deliverable_id = 5;
COMMIT;

SELECT SLEEP(GREATEST(0, 59 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i2_3;
SELECT click_count INTO @i2 FROM Deliverables WHERE deliverable_id = 5;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I2', 'I', IF(@i2 = 3202, 'OK', 'GAP'),
 CONCAT('A read ', @b2, ', B read ', @b2, ', click_count is now ', @i2, ' (started 3200, two clicks, expected 3202)'),
 'read-modify-write in application code; one increment was silently overwritten');

UPDATE Deliverables SET click_count = 3200 WHERE deliverable_id = 5;

-- ========== I3-RC  non-repeatable read ==========
-- DELIBERATE RELAXATION again.
SELECT SLEEP(GREATEST(0, 62 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rc_1;
SET SESSION transaction_isolation = 'READ-COMMITTED';
START TRANSACTION;
SELECT COALESCE(SUM(amount), 0) INTO @r1
FROM Transactions WHERE tournament_id = 1 AND type = 'revenue';

SELECT SLEEP(GREATEST(0, 69 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rc_2;
SELECT COALESCE(SUM(amount), 0) INTO @r2
FROM Transactions WHERE tournament_id = 1 AND type = 'revenue';
COMMIT;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I3-RC', 'I', IF(@r1 <> @r2, 'GAP', 'OK'),
 CONCAT('same query twice in one transaction: ', @r1, ' then ', @r2),
 'READ COMMITTED permits a non-repeatable read -- demonstration, not a schema defect');

SET SESSION transaction_isolation = DEFAULT;

-- ========== I3-RR  the same schedule at our default ==========
SELECT SLEEP(GREATEST(0, 76 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rr_1;
START TRANSACTION;
SELECT COALESCE(SUM(amount), 0) INTO @s1
FROM Transactions WHERE tournament_id = 1 AND type = 'revenue';

SELECT SLEEP(GREATEST(0, 83 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i3rr_2;
SELECT COALESCE(SUM(amount), 0) INTO @s2
FROM Transactions WHERE tournament_id = 1 AND type = 'revenue';
COMMIT;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I3-RR', 'I', IF(@s1 = @s2, 'OK', 'GAP'),
 CONCAT('same query twice in one transaction: ', @s1, ' then ', @s2),
 'REPEATABLE READ prevented the anomaly -- this is what our default buys us');

-- ========== I4a  write skew, prize pool ==========
SELECT SLEEP(GREATEST(0, 95 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4a_1;
START TRANSACTION;
SELECT (SELECT prize_pool FROM Tournament WHERE tournament_id = 2)
     - COALESCE(SUM(amount), 0) INTO @hb
FROM Payments WHERE tournament_id = 2 AND payee_type = 'team';

SELECT SLEEP(GREATEST(0, 101 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4a_2;
INSERT INTO Payments
    (payee_type, staff_user_id, team_id, tournament_id, amount, status, payment_date)
VALUES ('team', NULL, 3, 2, 1000.00, 'paid', CURRENT_DATE);
COMMIT;

SELECT SLEEP(GREATEST(0, 104 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4a_3;
SELECT COALESCE(SUM(amount), 0) INTO @tot
FROM Payments WHERE tournament_id = 2 AND payee_type = 'team';
SELECT prize_pool INTO @pool FROM Tournament WHERE tournament_id = 2;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I4a', 'I', IF(@tot > @pool, 'GAP', 'OK'),
 CONCAT('headroom seen by B: ', @hb, ' -- pool ', @pool, ' vs team payouts ', @tot),
 'nothing relaxed: both transactions passed the same headroom check at our REPEATABLE READ default and the pool was overdrawn');

DELETE FROM Payments
WHERE tournament_id = 2 AND payee_type = 'team' AND amount = 1000.00
  AND payment_date = CURRENT_DATE;
UPDATE Payments SET amount = 2000.00 WHERE payment_id = 3;

-- ========== I4b  write skew, player on two teams ==========
SELECT SLEEP(GREATEST(0, 110 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4b_1;
START TRANSACTION;
SELECT COUNT(*) INTO @rb FROM Roster WHERE player_id = 47 AND leave_date IS NULL;

SELECT SLEEP(GREATEST(0, 116 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4b_2;
INSERT INTO Roster (player_id, team_id, join_date, leave_date, salary, jersey_number)
VALUES (47, 6, CURRENT_DATE, NULL, 900.00, 10);
COMMIT;

SELECT SLEEP(GREATEST(0, 119 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4b_3;
SELECT COUNT(*) INTO @rt FROM Roster WHERE player_id = 47 AND leave_date IS NULL;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I4b', 'I', IF(@rt > 1, 'GAP', 'OK'),
 CONCAT('active teams seen by B before inserting: ', @rb, ' -- active roster rows now: ', @rt),
 'both sessions saw zero active teams for player 47 and each added a different one');

DELETE FROM Roster WHERE player_id = 47;

-- ========== I4c  write skew, duplicate seed ==========
SELECT SLEEP(GREATEST(0, 125 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4c_1;
START TRANSACTION;
SELECT COALESCE(MAX(seed), 0) + 1 INTO @sb FROM Registration WHERE tournament_id = 2;

SELECT SLEEP(GREATEST(0, 131 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4c_2;
INSERT INTO Registration (competitor_id, tournament_id, registration_date, seed)
VALUES (6, 2, CURRENT_DATE, @sb);
COMMIT;

SELECT SLEEP(GREATEST(0, 134 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4c_3;
SELECT COUNT(*) INTO @sc FROM Registration WHERE tournament_id = 2 AND seed = 5;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I4c', 'I', IF(@sc > 1, 'GAP', 'OK'),
 CONCAT('next seed computed by B: ', @sb, ' -- competitors now on seed 5: ', @sc),
 'the SELECT-then-INSERT pattern from the closing exercise of CSC370-19, with our own table');

DELETE FROM Registration WHERE tournament_id = 2 AND competitor_id IN (5, 6);

-- ========== I4-FIX  the same race through sp_register_team ==========
SELECT SLEEP(GREATEST(0, 137 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4fix_1;
CALL sp_register_team(6, 2, 5);

SELECT SLEEP(GREATEST(0, 142 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i4fix_2;
SELECT COUNT(*) INTO @fx FROM Registration WHERE tournament_id = 2 AND seed = 5;

INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('I4-FIX', 'I', IF(@fx = 1, 'OK', 'GAP'),
 CONCAT('competitors on seed 5 after both calls fired at the same instant: ', @fx),
 'FOR UPDATE on the Tournament row serialised the two calls; the loser got ERROR 1644');

DELETE FROM Registration WHERE tournament_id = 2 AND competitor_id IN (5, 6);

-- ========== I5  write skew across tables ==========
SELECT SLEEP(GREATEST(0, 148 - (UNIX_TIMESTAMP(NOW(3)) - @t0))) AS _i5;
UPDATE Membership SET left_date = CURRENT_DATE WHERE user_id = 10 AND org_id = 1;
BSQL

# Same anchor for both, two seconds of lead-in so neither starts mid-connect.
T0=$(( $(date +%s) + 2 ))
sed "s/__T0__/$T0/" "$WORK/a.tmpl" > "$WORK/a.sql"
sed "s/__T0__/$T0/" "$WORK/b.tmpl" > "$WORK/b.sql"

echo "==> running both sessions concurrently (about 165 seconds)"
mysql_root --force -t -v --comments "$DB" < "$WORK/a.sql" > "$WORK/a.out" 2>&1 &
APID=$!
mysql_root --force -t -v --comments "$DB" < "$WORK/b.sql" > "$WORK/b.out" 2>&1 &
BPID=$!
wait $APID $BPID
echo "    done"

# --- transcript --------------------------------------------------------
{
    echo "====================================================================="
    echo " ISOLATION TEST TRANSCRIPT"
    echo " Generated by run_isolation_tests.sh against MySQL $(mysql_root -N -B -e 'SELECT VERSION();' 2>/dev/null)"
    echo
    echo " Two concurrent sessions, synchronised on a shared clock anchor."
    echo " ERROR 1205 (lock wait timeout), 1213 (deadlock) and 1644 (our own"
    echo " SIGNAL) are EXPECTED RESULTS."
    echo
    echo " I1 and I3-RC deliberately relax the SESSION isolation level to show"
    echo " what our REPEATABLE READ default protects against. Those are"
    echo " demonstrations, not schema defects, and the level is reset after."
    echo " I4a, I4b, I4c and I5 relax NOTHING -- they run at our real default"
    echo " and the invariant still breaks."
    echo "====================================================================="
    echo
    echo "#####################################################################"
    echo "# SESSION A"
    echo "#####################################################################"
    cat "$WORK/a.out"
    echo
    echo "#####################################################################"
    echo "# SESSION B"
    echo "#####################################################################"
    cat "$WORK/b.out"
    echo
    echo "====================================================================="
    echo " VERDICTS"
    echo "====================================================================="
} > "$OUT"

# Anchor the pattern to the start of the line. mysql prints its errors at
# column 0, whereas our own detail strings mention "ERROR 1205" and "ERROR
# 1644" mid-line and are echoed back by -v -- an unanchored grep counts those
# too and reports phantom extras.
count_err() { grep -ch "^$1" "$WORK/a.out" "$WORK/b.out" 2>/dev/null | awk '{s+=$1} END{print s+0}'; }
TIMEOUTS=$(count_err 'ERROR 1205')
DEADLOCKS=$(count_err 'ERROR 1213')
SIGNALS=$(count_err 'ERROR 1644')

# A4's outcome lives in the transcript, not in table state: both sessions roll
# back either way, so nothing in the data distinguishes "one session was killed
# by the deadlock detector" from "they never collided". Recording it here keeps
# that derivation explicit rather than hiding it in a row-derived verdict.
mysql_root "$DB" -e "
INSERT INTO isolation_results (test, property, verdict, evidence, detail) VALUES
('A4', 'A', IF($DEADLOCKS = 1, 'OK', 'FAIL'),
 'ERROR 1213 raised: $DEADLOCKS (expected 1)',
 'the deadlock detector rolled back the whole transaction of the victim -- contrast with A3, where a lock-wait timeout rolled back only one statement. Derived from the transcript, not from table state.');
" 2>/dev/null

mysql_root -t "$DB" -e \
    "SELECT seq, test, property, verdict, evidence, detail FROM isolation_results ORDER BY seq;" \
    >> "$OUT" 2>&1

{
    echo
    echo "ERROR 1205 (lock wait timeout) raised : $TIMEOUTS   [A3 expects 1]"
    echo "ERROR 1213 (deadlock) raised          : $DEADLOCKS   [A4 expects 1]"
    echo "ERROR 1644 (our SIGNAL) raised        : $SIGNALS   [I4-FIX expects 1]"
} >> "$OUT"

echo "==> wrote $OUT"
echo
mysql_root -t "$DB" -e \
    "SELECT test, verdict, evidence FROM isolation_results ORDER BY seq;" 2>/dev/null
echo
echo "ERROR 1205 (lock wait timeout): $TIMEOUTS   [A3 expects 1]"
echo "ERROR 1213 (deadlock)         : $DEADLOCKS   [A4 expects 1]"
echo "ERROR 1644 (our SIGNAL)       : $SIGNALS   [I4-FIX expects 1]"

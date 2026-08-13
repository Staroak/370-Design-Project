<#
=====================================================================
 run_durability_tests.ps1

 The D half of the ACID audit. Needs an ELEVATED PowerShell, because it has
 to kill and restart the MySQL80 Windows service -- a hard kill is the only
 way to test durability honestly. A clean shutdown flushes everything and
 would prove nothing.

   Right-click PowerShell -> Run as Administrator
   cd "c:\CSC370 Project\370-Design-Project\sql"
   .\run_durability_tests.ps1 -RootPassword '<your-root-password>'

 Writes durability_test_output.txt.

 THREE TESTS
   D1  commit, hard-kill, restart      -> the row MUST survive  (redo log)
   D2  same with innodb_flush_log_at_trx_commit = 0
                                       -> the row is LOST despite a
                                          successful COMMIT
   D3  insert without committing, hard-kill
                                       -> the row MUST be absent (undo log)

 D2 is a DELIBERATE RELAXATION of a server setting, not a defect in our
 schema. It shows that durability is a configuration property rather than
 something InnoDB gives you unconditionally. The setting is a runtime GLOBAL,
 not persisted, so the restart in the middle of the test restores it to the
 my.ini value on its own -- there is no way to leave the server unsafe.

 RISK: this hard-kills the database server. Everything in
 design_project_370 is regenerable from 01_create_tables.sql and
 02_insert_data.sql, and InnoDB crash recovery is routine, but do not run
 this against anything you care about.
=====================================================================
#>

param(
    [Parameter(Mandatory = $true)][string]$RootPassword,
    [string]$MySqlBin = 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe',
    [string]$ServiceName = 'MySQL80',
    [string]$Database = 'design_project_370'
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot
$OutFile = Join-Path $PSScriptRoot 'durability_test_output.txt'
$Results = @()

# --- preconditions ----------------------------------------------------
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($id)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must run in an ELEVATED PowerShell." -ForegroundColor Red
    Write-Host "Right-click PowerShell -> Run as Administrator, then re-run."
    exit 1
}
if (-not (Test-Path $MySqlBin)) {
    Write-Host "mysql.exe not found at $MySqlBin -- pass -MySqlBin <path>" -ForegroundColor Red
    exit 1
}

function Invoke-MySql {
    param([string]$Sql)
    & $MySqlBin '-u' 'root' "-p$RootPassword" '-N' '-B' $Database '-e' $Sql
}

function Wait-ForMySql {
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $r = & $MySqlBin '-u' 'root' "-p$RootPassword" '-N' '-B' '-e' 'SELECT 1'
            if ($LASTEXITCODE -eq 0) { return $true }
        } catch { }
        Start-Sleep -Seconds 2
    }
    return $false
}

# A hard kill, not Stop-Service. Stop-Service asks mysqld to shut down
# cleanly, which flushes the buffer pool and makes every test below pass
# for the wrong reason.
function Stop-MySqlHard {
    $p = Get-Process -Name 'mysqld' -ErrorAction SilentlyContinue
    if ($null -eq $p) { throw 'mysqld is not running' }
    Stop-Process -Id $p.Id -Force
    Start-Sleep -Seconds 4
}

function Start-MySqlAgain {
    Start-Service -Name $ServiceName
    if (-not (Wait-ForMySql)) { throw "MySQL did not come back after restart" }
}

function Add-Result {
    param([string]$Test, [string]$Verdict, [string]$Evidence, [string]$Detail)
    $script:Results += [PSCustomObject]@{
        Test = $Test; Verdict = $Verdict; Evidence = $Evidence; Detail = $Detail
    }
    Write-Host ("  {0,-4} {1,-5} {2}" -f $Test, $Verdict, $Evidence)
}

# --- baseline ---------------------------------------------------------
Write-Host "==> preflight"
if (-not (Wait-ForMySql)) { Write-Host "cannot reach MySQL" -ForegroundColor Red; exit 1 }

Invoke-MySql "DELETE FROM Transactions WHERE category LIKE 'durability-%';" | Out-Null
$flush = Invoke-MySql "SELECT @@innodb_flush_log_at_trx_commit;"
Write-Host "    innodb_flush_log_at_trx_commit = $flush"

# =====================================================================
# D1  committed work must survive a crash
# =====================================================================
Write-Host "==> D1  commit, hard-kill, restart"
Invoke-MySql @"
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
START TRANSACTION;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, 1, 'revenue', 'durability-d1', 111.00, CURRENT_DATE);
COMMIT;
"@ | Out-Null

Stop-MySqlHard
Start-MySqlAgain

$d1 = [int](Invoke-MySql "SELECT COUNT(*) FROM Transactions WHERE category = 'durability-d1';")
if ($d1 -eq 1) { $v = 'OK' } else { $v = 'FAIL' }
Add-Result 'D1' $v "rows surviving the crash: $d1 (expected 1)" `
    'redo log replay: COMMIT was acknowledged only after the log record reached disk (CSC370-18)'

# =====================================================================
# D2  the same commit with the flush guarantee turned off
# =====================================================================
Write-Host "==> D2  same, with innodb_flush_log_at_trx_commit = 0"
Invoke-MySql "SET GLOBAL innodb_flush_log_at_trx_commit = 0;" | Out-Null
Invoke-MySql @"
START TRANSACTION;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, 1, 'revenue', 'durability-d2', 222.00, CURRENT_DATE);
COMMIT;
"@ | Out-Null

# Kill at once. At 0 the log is flushed about once a second, so any delay
# here lets the row survive and the test reports OK for the wrong reason.
Stop-MySqlHard
Start-MySqlAgain

$d2 = [int](Invoke-MySql "SELECT COUNT(*) FROM Transactions WHERE category = 'durability-d2';")
if ($d2 -eq 0) {
    Add-Result 'D2' 'GAP' "rows surviving the crash: $d2 (COMMIT said success)" `
        'durability is a configuration property: at 0 a committed transaction is lost on a crash'
} else {
    Add-Result 'D2' 'RETRY' "row survived: $d2" `
        'at 0 the log still flushes about once a second, so the kill landed after a flush. Re-run; if it survives repeatedly, report that honestly rather than forcing the result'
}

$flushNow = Invoke-MySql "SELECT @@innodb_flush_log_at_trx_commit;"
Add-Result 'D2-RESET' $(if ("$flushNow" -eq '1') { 'OK' } else { 'FAIL' }) `
    "innodb_flush_log_at_trx_commit is now $flushNow" `
    'the restart restored the my.ini value on its own; the relaxation was never persisted'

# =====================================================================
# D3  uncommitted work must NOT survive
# =====================================================================
Write-Host "==> D3  open transaction, no commit, hard-kill"
$d3File = Join-Path $env:TEMP 'acid_d3.sql'
@"
START TRANSACTION;
INSERT INTO Transactions (org_id, tournament_id, type, category, amount, date)
VALUES (1, 2, 'revenue', 'durability-d3', 333.00, CURRENT_DATE);
SELECT SLEEP(60);
COMMIT;
"@ | Set-Content -Path $d3File -Encoding utf8

$proc = Start-Process -FilePath $MySqlBin `
    -ArgumentList '-u', 'root', "-p$RootPassword", $Database `
    -RedirectStandardInput $d3File -PassThru -NoNewWindow
Start-Sleep -Seconds 6      # inside the SLEEP, transaction open, nothing committed

Stop-MySqlHard
if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
Start-MySqlAgain

$d3 = [int](Invoke-MySql "SELECT COUNT(*) FROM Transactions WHERE category = 'durability-d3';")
if ($d3 -eq 0) { $v = 'OK' } else { $v = 'FAIL' }
Add-Result 'D3' $v "rows surviving the crash: $d3 (expected 0)" `
    'undo log at crash recovery: an incomplete transaction is rolled back on restart'

# --- cleanup and report ----------------------------------------------
Invoke-MySql "DELETE FROM Transactions WHERE category LIKE 'durability-%';" | Out-Null
$residue = [int](Invoke-MySql "SELECT COUNT(*) FROM Transactions WHERE category LIKE 'durability-%';")
Add-Result 'D-RESIDUE' $(if ($residue -eq 0) { 'OK' } else { 'FAIL' }) `
    "stray rows left: $residue" 'the run must leave the data as 02_insert_data.sql left it'

$version = Invoke-MySql "SELECT VERSION();"
$header = @"
=====================================================================
 DURABILITY TEST TRANSCRIPT
 Generated by run_durability_tests.ps1 against MySQL $version

 The server was HARD-KILLED (Stop-Process -Force), not shut down cleanly.
 A clean shutdown flushes everything and would make all three tests pass
 for the wrong reason.

 D2 deliberately relaxes a SERVER SETTING, not the schema. It shows that
 durability is a configuration property, not something InnoDB gives you
 unconditionally. The setting is a runtime GLOBAL and is not persisted, so
 the restart restores the my.ini value by itself -- see D2-RESET.
=====================================================================

"@

$header | Set-Content -Path $OutFile -Encoding utf8
$Results | Format-Table -AutoSize | Out-String -Width 200 | Add-Content -Path $OutFile -Encoding utf8

Write-Host ""
Write-Host "==> wrote $OutFile"
$Results | Format-Table -AutoSize

<#
.SYNOPSIS
    Non-destructively diagnose Hermes session history anomalies.
.DESCRIPTION
    Reports true ghost sessions, stale message_count metadata, multi-child
    compression lineages, and severe compression ratios across the default
    Hermes runtime DB and profile DBs. This script never deletes or updates
    session data.
.PARAMETER RuntimeRoot
    Hermes runtime root. Defaults to this repository's .tools/hermes-worker.
#>

[CmdletBinding()]
param(
    [string]$RuntimeRoot = "E:\UEGameDevelopment\.tools\hermes-worker"
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Invoke-SqlitePython {
    param(
        [Parameter(Mandatory=$true)][string]$DbPath,
        [Parameter(Mandatory=$true)][string]$Label
    )

    $script = @'
import json
import sqlite3
import sys

db_path = sys.argv[1]
label = sys.argv[2]

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row

def rows(sql, params=()):
    return [dict(r) for r in conn.execute(sql, params).fetchall()]

sessions = conn.execute("SELECT COUNT(*) FROM sessions").fetchone()[0]
messages = conn.execute("SELECT COUNT(*) FROM messages").fetchone()[0]
end_reasons = rows("""
    SELECT COALESCE(end_reason, '<active>') AS end_reason, COUNT(*) AS count
    FROM sessions
    GROUP BY COALESCE(end_reason, '<active>')
    ORDER BY count DESC, end_reason
""")

ghosts = rows("""
    SELECT s.id, s.title, s.parent_session_id, s.end_reason, s.started_at, s.ended_at
    FROM sessions s
    WHERE s.message_count = 0
      AND NOT EXISTS (SELECT 1 FROM messages m WHERE m.session_id = s.id)
    ORDER BY s.started_at DESC
    LIMIT 50
""")

metadata_drift = rows("""
    SELECT s.id, s.title, s.parent_session_id, s.end_reason,
           s.message_count AS metadata_count,
           COUNT(m.id) AS actual_count
    FROM sessions s
    JOIN messages m ON m.session_id = s.id
    WHERE s.message_count = 0
    GROUP BY s.id
    ORDER BY actual_count DESC, s.started_at DESC
    LIMIT 50
""")

multi_child = rows("""
    SELECT p.id, p.title, p.end_reason, p.message_count,
           COUNT(c.id) AS child_count,
           GROUP_CONCAT(c.id, ' | ') AS children
    FROM sessions p
    JOIN sessions c ON c.parent_session_id = p.id
    GROUP BY p.id
    HAVING COUNT(c.id) > 1
    ORDER BY child_count DESC, p.started_at DESC
    LIMIT 50
""")

compression_ratios = rows("""
    SELECT p.id AS parent_id,
           p.title,
           p.message_count AS before_msgs,
           c.id AS child_id,
           c.message_count AS after_msgs,
           CASE
             WHEN p.message_count > 0 THEN ROUND(CAST(c.message_count AS REAL) / p.message_count, 4)
             ELSE NULL
           END AS ratio
    FROM sessions p
    JOIN sessions c ON c.parent_session_id = p.id
    WHERE p.end_reason = 'compression'
      AND p.message_count >= 20
      AND c.started_at >= p.ended_at
      AND c.message_count < p.message_count * 0.25
    ORDER BY ratio ASC, p.message_count DESC
    LIMIT 50
""")

print(json.dumps({
    "label": label,
    "db_path": db_path,
    "sessions": sessions,
    "messages": messages,
    "end_reasons": end_reasons,
    "true_ghost_sessions": ghosts,
    "metadata_zero_but_actual_messages": metadata_drift,
    "multi_child_parents": multi_child,
    "severe_compression_ratios": compression_ratios,
}, ensure_ascii=False, indent=2))

conn.close()
'@

    $tmp = New-TemporaryFile
    try {
        Set-Content -LiteralPath $tmp -Value $script -Encoding UTF8
        python $tmp $DbPath $Label
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $RuntimeRoot)) {
    Write-Error "Runtime root not found: $RuntimeRoot"
}

$dbs = @()
$defaultDb = Join-Path $RuntimeRoot "state.db"
if (Test-Path -LiteralPath $defaultDb) {
    $dbs += [pscustomobject]@{ Label = "default"; Path = $defaultDb }
}

$profilesDir = Join-Path $RuntimeRoot "profiles"
if (Test-Path -LiteralPath $profilesDir) {
    Get-ChildItem -LiteralPath $profilesDir -Directory | ForEach-Object {
        $db = Join-Path $_.FullName "state.db"
        if (Test-Path -LiteralPath $db) {
            $dbs += [pscustomobject]@{ Label = $_.Name; Path = $db }
        }
    }
}

if ($dbs.Count -eq 0) {
    Write-Warning "No Hermes state.db files found under $RuntimeRoot"
    exit 0
}

Write-Section "Hermes session diagnostics"
Write-Host "Runtime root: $RuntimeRoot"
Write-Host "Databases: $($dbs.Count)"
Write-Host "Mode: read-only diagnostics; no session rows are modified."

foreach ($db in $dbs) {
    Write-Section $db.Label
    Invoke-SqlitePython -DbPath $db.Path -Label $db.Label
}

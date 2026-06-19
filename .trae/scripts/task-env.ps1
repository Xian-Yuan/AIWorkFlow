﻿# Task Env 鈥?鑴氭湰鍙戠幇涓庣幆澧冨彉閲忓鍑?# 鐢ㄦ硶: . .\.trae\scripts\task-env.ps1
# 瀵煎嚭: $TASK_STATE, $TASK_GUARD

$ScriptDir = $PSScriptRoot

# 瀵煎嚭鑴氭湰璺緞
$TASK_STATE = Join-Path $ScriptDir "task-state.ps1"
$TASK_GUARD = Join-Path $ScriptDir "task-guard.ps1"
$TASK_METRICS = Join-Path $ScriptDir "task-metrics.ps1"

# 楠岃瘉鑴氭湰瀛樺湪
if (-not (Test-Path $TASK_STATE)) {
    Write-Host "ERROR: task-state.ps1 not found at $TASK_STATE" -ForegroundColor Red
}
if (-not (Test-Path $TASK_GUARD)) {
    Write-Host "ERROR: task-guard.ps1 not found at $TASK_GUARD" -ForegroundColor Red
}
if (-not (Test-Path $TASK_METRICS)) {
    Write-Host "WARN: task-metrics.ps1 not found at $TASK_METRICS (metrics collection disabled)" -ForegroundColor Yellow
}

# 瀵煎嚭鍒板叏灞€浣滅敤鍩?$global:TASK_STATE = $TASK_STATE
$global:TASK_GUARD = $TASK_GUARD
$global:TASK_METRICS = $TASK_METRICS

Write-Host "[ENV] Task scripts loaded" -ForegroundColor Green
Write-Host "  TASK_STATE=$global:TASK_STATE" -ForegroundColor Gray
Write-Host "  TASK_GUARD=$global:TASK_GUARD" -ForegroundColor Gray
Write-Host "  TASK_METRICS=$global:TASK_METRICS" -ForegroundColor Gray

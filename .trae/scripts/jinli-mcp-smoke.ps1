# ============================================================
# jinli-mcp-smoke.ps1 — WP04 Scope A Smoke Test
# 版本: WP04-2026-06-28 | 范围: 验证 soul_memory 走 daemon HTTP
# ============================================================
#
# 用途：在 daemon 启动 → soulMemoryHandler 调用 → daemon 在线/离线
#      fallback 全链路 smoke 一次，确保：
#   1. daemon 启动成功（health endpoint OK）
#   2. Python client.memory_query 能调通
#   3. Node plugin side 也能正确判定 daemon 状态
#   4. daemon 停止后 plugin side 走 fallback
#
# 与 WP04-adapter-migration.md 配合阅读。
# ============================================================

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$workspaceRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$pluginRoot    = "C:\Users\87372\plugins\jinli-soul-core"
$stateDir      = "E:\UEGameDevelopment\Project\Jinli\services\runtime\daemon-state"
$endpointFile  = Join-Path $stateDir "daemon.endpoint"

Write-Host "===== WP04 Scope A Smoke Test =====" -ForegroundColor Cyan
Write-Host "Workspace: $workspaceRoot"
Write-Host "Plugin:    $pluginRoot"
Write-Host "Endpoint:  $endpointFile"
Write-Host ""

# ──── Step 1: 启动 daemon ────────────────
Write-Host "[1/5] 启动 daemon..." -ForegroundColor Yellow
$startOut = & "$workspaceRoot\.trae\scripts\jinli-system.ps1" start 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0 -or -not $startOut.ok) {
    Write-Host "FAIL: daemon 启动失败" -ForegroundColor Red
    exit 1
}
Write-Host "  daemon online: pid=$($startOut.pid) port=$($startOut.endpoint.port)"

# ──── Step 2: Python client 走 daemon HTTP ────────────────
Write-Host ""
Write-Host "[2/5] Python client memory_query 走 daemon HTTP..." -ForegroundColor Yellow
$pyScript = Join-Path $env:TEMP "wp04_smoke_step2.py"
@'
import sys
sys.path.insert(0, r'E:\UEGameDevelopment')
from Project.Jinli.services.runtime.client import JinliClient
c = JinliClient()
if not c.is_online():
    print('OFFLINE')
    sys.exit(2)
r = c.memory_query('jinli system')
print('STATUS: 200' if r else 'STATUS: NULL')
if isinstance(r, dict):
    print(f'KEYS: {list(r.keys())}')
    items = r.get('items') or r.get('memory_evidence') or []
    print(f'ITEMS: {len(items)}')
'@ | Set-Content -LiteralPath $pyScript -Encoding UTF8

$pyOut = python $pyScript 2>&1
Remove-Item -LiteralPath $pyScript -Force -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: Python client memory_query failed" -ForegroundColor Red
    Write-Host $pyOut
    & "$workspaceRoot\.trae\scripts\jinli-system.ps1" stop | Out-Null
    exit 1
}
Write-Host "  Python client: $pyOut"

# ──── Step 3: Node plugin side 判定 daemon 状态 ────────────────
Write-Host ""
Write-Host "[3/5] Node plugin side daemon 状态判定..." -ForegroundColor Yellow
$jsScript = Join-Path $env:TEMP "wp04_smoke_step3.mjs"
@"
import { readEndpoint, isDaemonOnline } from 'file:///C:/Users/87372/plugins/jinli-soul-core/mcp/lib/daemon-http.mjs';
const ep = readEndpoint();
if (!ep) { console.log('EP_NULL'); process.exit(2); }
console.log('EP=' + JSON.stringify(ep));
const online = await isDaemonOnline();
console.log('ONLINE=' + online);
"@ | Set-Content -LiteralPath $jsScript -Encoding UTF8

$nodeOut = node $jsScript 2>&1
Remove-Item -LiteralPath $jsScript -Force -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: Node plugin readEndpoint failed" -ForegroundColor Red
    Write-Host $nodeOut
    & "$workspaceRoot\.trae\scripts\jinli-system.ps1" stop | Out-Null
    exit 1
}
Write-Host "  Node plugin: $nodeOut"

# ──── Step 4: 停 daemon，验证 fallback 路径 ────────────────
Write-Host ""
Write-Host "[4/5] 停 daemon，验证 fallback..." -ForegroundColor Yellow
& "$workspaceRoot\.trae\scripts\jinli-system.ps1" stop | Out-Null

$jsScript2 = Join-Path $env:TEMP "wp04_smoke_step4.mjs"
@"
import { readEndpoint, isDaemonOnline } from 'file:///C:/Users/87372/plugins/jinli-soul-core/mcp/lib/daemon-http.mjs';
const ep = readEndpoint();
console.log('AFTER_STOP_EP_NULL=' + (ep === null));
const online = await isDaemonOnline();
console.log('AFTER_STOP_ONLINE=' + online);
"@ | Set-Content -LiteralPath $jsScript2 -Encoding UTF8

$fallbackOut = node $jsScript2 2>&1
Remove-Item -LiteralPath $jsScript2 -Force -ErrorAction SilentlyContinue
Write-Host "  Fallback check: $fallbackOut"

# ──── Step 5: 结论 ────────────────
Write-Host ""
Write-Host "[5/5] 结论" -ForegroundColor Yellow
if ($fallbackOut -match "AFTER_STOP_EP_NULL=true" -and $fallbackOut -match "AFTER_STOP_ONLINE=false") {
    Write-Host "  PASS: daemon 在线时 Node plugin 可读 endpoint；停 daemon 后正确返回 null/false" -ForegroundColor Green
    Write-Host ""
    Write-Host "===== SMOKE TEST PASSED =====" -ForegroundColor Green
    exit 0
} else {
    Write-Host "  FAIL: fallback 路径异常" -ForegroundColor Red
    Write-Host "===== SMOKE TEST FAILED =====" -ForegroundColor Red
    exit 1
}

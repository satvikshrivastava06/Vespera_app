# Vespera — reliable Flutter web dev (hot reload, no stale port 8080)
# Usage:
#   .\scripts\dev_web.ps1          # recommended: Chrome + hot reload
#   .\scripts\dev_web.ps1 -Server  # localhost only (manual refresh; not recommended)

param(
    [switch]$Server
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Stop-PortListener {
    param([int]$Port)
    $killed = $false
    $lines = netstat -ano | Select-String ":$Port\s+.*LISTENING"
    foreach ($line in $lines) {
        if ($line -match '\s(\d+)\s*$') {
            $procId = [int]$Matches[1]
            if ($procId -gt 0) {
                Write-Host "Releasing port $Port (PID $procId)..."
                taskkill /PID $procId /F 2>$null | Out-Null
                $killed = $true
            }
        }
    }
    if ($killed) {
        Start-Sleep -Milliseconds 600
    }
}

Write-Host ""
Write-Host "=== Vespera web dev ===" -ForegroundColor Cyan
Stop-PortListener -Port 8080

if ($Server) {
    Write-Host "Mode: web-server (http://localhost:8080)" -ForegroundColor Yellow
    Write-Host "You must hard-refresh the browser after code changes (Ctrl+F5)." -ForegroundColor Yellow
    Write-Host ""
    flutter run -d web-server --web-hostname localhost --web-port 8080
} else {
    Write-Host "Mode: Chrome (recommended)" -ForegroundColor Green
    Write-Host "  - Save any .dart file in Cursor  ->  hot reload (if enabled in settings)" -ForegroundColor Gray
    Write-Host "  - Press 'r' in this terminal     ->  hot reload" -ForegroundColor Gray
    Write-Host "  - Press 'R' in this terminal     ->  hot restart" -ForegroundColor Gray
    Write-Host "  - Press 'q'                      ->  quit" -ForegroundColor Gray
    Write-Host ""
    flutter run -d chrome --web-port 8080
}

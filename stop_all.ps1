$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root "runtime_logs\pids.json"

if (-not (Test-Path $pidFile)) {
    Write-Host "No PID file found at $pidFile"
    exit 0
}

$items = Get-Content $pidFile -Raw | ConvertFrom-Json
foreach ($item in $items) {
    if ($item.pid) {
        Stop-Process -Id $item.pid -ErrorAction SilentlyContinue
        Write-Host "Stopped $($item.module) (PID $($item.pid))"
    }
}


$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$python = Join-Path $root ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    throw "Missing virtualenv Python at $python. Run 'python -m uv sync' first."
}

$logDir = Join-Path $root "runtime_logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$services = @(
    @{ Module = "registry"; Name = "registry"; Delay = 2 },
    @{ Module = "tax_agent"; Name = "tax_agent"; Delay = 2 },
    @{ Module = "compliance_agent"; Name = "compliance_agent"; Delay = 3 },
    @{ Module = "law_agent"; Name = "law_agent"; Delay = 3 },
    @{ Module = "customer_agent"; Name = "customer_agent"; Delay = 0 }
)

$started = @()
foreach ($service in $services) {
    $stdout = Join-Path $logDir "$($service.Name).out.log"
    $stderr = Join-Path $logDir "$($service.Name).err.log"

    $proc = Start-Process `
        -FilePath $python `
        -ArgumentList "-m", $service.Module `
        -WorkingDirectory $root `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr `
        -WindowStyle Hidden `
        -PassThru

    $started += [pscustomobject]@{
        module = $service.Module
        pid = $proc.Id
        stdout = $stdout
        stderr = $stderr
    }

    if ($service.Delay -gt 0) {
        Start-Sleep -Seconds $service.Delay
    }
}

$pidFile = Join-Path $logDir "pids.json"
$started | ConvertTo-Json -Compress | Set-Content -Path $pidFile -Encoding UTF8

Write-Host ""
Write-Host "All Stage 5 services started."
Write-Host "  Registry:         http://localhost:10000"
Write-Host "  Customer Agent:   http://localhost:10100"
Write-Host "  Law Agent:        http://localhost:10101"
Write-Host "  Tax Agent:        http://localhost:10102"
Write-Host "  Compliance Agent: http://localhost:10103"
Write-Host ""
Write-Host "PID file: $pidFile"
Write-Host "Logs: $logDir"
Write-Host ""
Write-Host "Next:"
Write-Host "  .\.venv\Scripts\python.exe test_client.py"
Write-Host "Stop:"
Write-Host "  .\stop_all.ps1"

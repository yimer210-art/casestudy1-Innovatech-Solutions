# Start Rover Terraform Visualizer
# Gebruik: .\start-rover.ps1

Set-Location $PSScriptRoot

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Innovatech Solutions - Rover Terraform Visualizer  " -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Starten op http://localhost:9000 ..." -ForegroundColor Yellow

$RoverExe = Join-Path $PSScriptRoot "..\..\rover_bin\rover_v0.3.3.exe"
if (-not (Test-Path $RoverExe)) {
    Write-Error "Rover executable niet gevonden op: $RoverExe"
    exit 1
}

# Start de browser automatisch na 2 seconden zodra Rover online is
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:9000"
} | Out-Null

Write-Host "[*] Open in je browser: http://localhost:9000" -ForegroundColor Green
Write-Host "[*] Druk op Ctrl+C om de server te stoppen." -ForegroundColor Gray
Write-Host ""

# Belangrijk: -planJSONPath moet een relatief pad zijn op Windows om pad-duplicatie in Rover te voorkomen
& $RoverExe -planJSONPath "plan.json" -ipPort "127.0.0.1:9000"

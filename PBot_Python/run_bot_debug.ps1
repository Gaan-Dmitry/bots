$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$pythonExe = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    $pythonExe = Join-Path $PSScriptRoot "venv\Scripts\python.exe"
}
if (-not (Test-Path $pythonExe)) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand) {
        $pythonExe = $pythonCommand.Source
    } else {
        throw "Python was not found. Run .\setup.ps1 first."
    }
}

$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logDir "pbot-$stamp.log"

Write-Host "PBot diagnostic launch" -ForegroundColor Cyan
Write-Host "Python: $pythonExe"
Write-Host "Log:    $logFile"
Write-Host "Closing this window will stop the application. Errors will be saved to the log."
Write-Host ""

"Started: $(Get-Date -Format o)" | Set-Content -Path $logFile -Encoding UTF8
"Python: $pythonExe" | Add-Content -Path $logFile -Encoding UTF8

& $pythonExe -u ".\main.py" 2>&1 | Tee-Object -FilePath $logFile -Append
$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "PBot exited with code: $exitCode"
Write-Host "Log saved to: $logFile"
Read-Host "Copy the error text or attach the log, then press Enter to close"
exit $exitCode

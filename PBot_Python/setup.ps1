$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "PBot setup" -ForegroundColor Cyan
Write-Host "Project folder: $PSScriptRoot"

if (-not (Test-Path ".\requirements.txt")) {
    throw "requirements.txt was not found. Run this script from the PBot_Python folder."
}

if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 -m venv ".venv"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python -m venv ".venv"
} else {
    throw "Python was not found. Install Python 3 and enable Python Launcher or add Python to PATH."
}

if ($LASTEXITCODE -ne 0) {
    throw "Virtual environment creation failed (exit code $LASTEXITCODE). Check your Python installation."
}

$pythonExe = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    throw "The virtual environment was not created: $pythonExe was not found."
}

& $pythonExe -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    throw "pip upgrade failed (exit code $LASTEXITCODE)."
}

& $pythonExe -m pip install -r ".\requirements.txt"
if ($LASTEXITCODE -ne 0) {
    throw "Dependency installation failed (exit code $LASTEXITCODE)."
}

Write-Host ""
Write-Host "Setup completed successfully." -ForegroundColor Green
Write-Host "For diagnostics run: .\run_bot_debug.ps1"
Write-Host "For hidden launch run: .\run_bot.ps1"
Read-Host "Press Enter to exit"

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "PBot setup" -ForegroundColor Cyan
Write-Host "Каталог: $PSScriptRoot"

if (-not (Test-Path ".\requirements.txt")) {
    throw "Не найден requirements.txt. Запустите скрипт из каталога PBot_Python."
}

if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 -m venv ".venv"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    & python -m venv ".venv"
} else {
    throw "Python не найден. Установите Python 3 и включите Python Launcher или Python в PATH."
}

if ($LASTEXITCODE -ne 0) {
    throw "Не удалось создать .venv (код $LASTEXITCODE). Проверьте установку Python."
}

$pythonExe = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    throw "После создания окружения не найден $pythonExe."
}

& $pythonExe -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    throw "Не удалось обновить pip (код $LASTEXITCODE)."
}

& $pythonExe -m pip install -r ".\requirements.txt"
if ($LASTEXITCODE -ne 0) {
    throw "Не удалось установить зависимости (код $LASTEXITCODE)."
}

Write-Host ""
Write-Host "Установка завершена." -ForegroundColor Green
Write-Host "Для диагностики запустите: .\run_bot_debug.ps1"
Write-Host "Обычный скрытый запуск: .\run_bot.ps1"
Read-Host "Нажмите Enter для завершения"

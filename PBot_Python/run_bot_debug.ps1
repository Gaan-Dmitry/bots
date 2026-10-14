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
        throw "Python не найден. Сначала запустите .\setup.ps1."
    }
}

$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logDir "pbot-$stamp.log"

Write-Host "PBot — диагностический запуск" -ForegroundColor Cyan
Write-Host "Python: $pythonExe"
Write-Host "Лог:    $logFile"
Write-Host "Закрытие окна завершит приложение. Текст ошибки сохранится в логе."
Write-Host ""

"Started: $(Get-Date -Format o)" | Set-Content -Path $logFile -Encoding UTF8
"Python: $pythonExe" | Add-Content -Path $logFile -Encoding UTF8

& $pythonExe -u ".\main.py" 2>&1 | Tee-Object -FilePath $logFile -Append
$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "PBot завершился с кодом: $exitCode"
Write-Host "Лог сохранён: $logFile"
Read-Host "Скопируйте ошибку из окна или приложите лог. Нажмите Enter для закрытия"
exit $exitCode

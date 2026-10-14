# =========================================================================
# PBot v7.0 — Бесшумный лаунчер (Без окна консоли, с правами Администратора)
# =========================================================================

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin =$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {$arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList $arguments
    exit
}

Set-Location -Path $PSScriptRoot

# Ищем pythonw.exe (он запускает GUI без черного окна консоли)
if (Test-Path ".\.venv\Scripts\pythonw.exe") {
    $pythonwExe = ".\.venv\Scripts\pythonw.exe"
} elseif (Test-Path ".\venv\Scripts\pythonw.exe") {
    $pythonwExe = ".\venv\Scripts\pythonw.exe"
} else {
    $pythonwExe = "pythonw.exe"
}

# Запускаем HUD в фоновом процессе и сразу закрываем PowerShell
Start-Process -FilePath $pythonwExe -ArgumentList "main.py" -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
exit
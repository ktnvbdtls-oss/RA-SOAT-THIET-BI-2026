$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $root "run_intranet_server.ps1"
$taskName = "VNPost Device Inventory Web"

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Hay chay PowerShell bang quyen Administrator."
}

$pythonCandidates = @(
    (Join-Path $root "runtime\python\python.exe"),
    (Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe")
)
$pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
if ($pythonCommand) {
    $pythonCandidates += $pythonCommand.Source
}
$python = $pythonCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $python) {
    throw "Khong tim thay Python. Hay cai Python 3.10+."
}

& $python -c "import openpyxl" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Python chua co openpyxl. Chay: python -m pip install -r requirements.txt"
}

New-Item -ItemType Directory -Force -Path (Join-Path $root "data") | Out-Null
Set-Content -Path (Join-Path $root "data\python-path.txt") -Value $python -Encoding UTF8

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$runner`"" `
    -WorkingDirectory $root
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 5 `
    -RestartInterval (New-TimeSpan -Minutes 1)
$taskPrincipal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $taskPrincipal `
    -Force | Out-Null

Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 4

Write-Host "Da cai Task Scheduler: $taskName"
Write-Host "Server se tu chay khi Windows khoi dong."
Write-Host "URL: http://10.43.128.10:8789/"

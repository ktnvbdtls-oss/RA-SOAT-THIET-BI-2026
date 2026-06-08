param(
    [string]$ServerUrl = "http://10.43.128.10:8789"
)

$ErrorActionPreference = "Stop"
$taskName = "VNPost Device Inventory Agent"
$sourceDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceAgent = Join-Path $sourceDirectory "managed_client_agent.ps1"
$installDirectory = Join-Path $env:ProgramData "VNPostDeviceInventory"
$installedAgent = Join-Path $installDirectory "managed_client_agent.ps1"

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Hay chay script bang quyen Administrator hoac trien khai bang Group Policy Computer Startup."
}
if (-not (Test-Path $sourceAgent)) {
    throw "Khong tim thay managed_client_agent.ps1 trong cung thu muc."
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceAgent -Destination $installedAgent -Force

$escapedServerUrl = $ServerUrl.Replace('"', '""')
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedAgent`" -ServerUrl `"$escapedServerUrl`""
$startupTrigger = New-ScheduledTaskTrigger -AtStartup
$periodicTrigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
$taskPrincipal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger @($startupTrigger, $periodicTrigger) `
    -Settings $settings `
    -Principal $taskPrincipal `
    -Force | Out-Null

Start-ScheduledTask -TaskName $taskName
Write-Host "Da cai agent nen: $taskName"
Write-Host "Agent gui cau hinh moi 15 phut den $ServerUrl"

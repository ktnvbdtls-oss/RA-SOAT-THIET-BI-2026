$ErrorActionPreference = "Stop"
$taskName = "VNPost Device Inventory Agent"
$installDirectory = Join-Path $env:ProgramData "VNPostDeviceInventory"

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Hay chay PowerShell bang quyen Administrator."
}

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $installDirectory -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Da go agent nen: $taskName"

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backgroundScript = Join-Path $root "start_intranet_background.ps1"

if (-not (Test-Path $backgroundScript)) {
    throw "Khong tim thay script: $backgroundScript"
}

& powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $backgroundScript

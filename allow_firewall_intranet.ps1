$ErrorActionPreference = "Stop"

$port = 8789
$ruleName = "VNPost Device Inventory Web $port"

$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Set-NetFirewallRule `
        -DisplayName $ruleName `
        -Enabled True `
        -Direction Inbound `
        -Action Allow `
        -Profile Any | Out-Null
    Get-NetFirewallRule -DisplayName $ruleName |
        Get-NetFirewallAddressFilter |
        Set-NetFirewallAddressFilter -RemoteAddress LocalSubnet
    Write-Host "Da cap nhat firewall rule: $ruleName"
    return
}

New-NetFirewallRule `
    -DisplayName $ruleName `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort $port `
    -Profile Any `
    -RemoteAddress LocalSubnet | Out-Null

Write-Host "Da mo cong TCP $port cho LocalSubnet tren moi network profile."

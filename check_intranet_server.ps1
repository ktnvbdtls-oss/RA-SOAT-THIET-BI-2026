$ErrorActionPreference = "Continue"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8789
$expectedIp = "10.43.128.10"
$logPath = Join-Path $root "logs\intranet-server.log"

Write-Host "=== KIEM TRA MAY CHU NOI BO ==="

$ipExists = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -eq $expectedIp }
if ($ipExists) {
    Write-Host "[OK] May nay dang so huu IP $expectedIp."
} else {
    Write-Host "[LOI] Khong tim thay IP $expectedIp tren card mang cua may nay."
    Write-Host "Cac IPv4 hien co:"
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike "127.*" } |
        Select-Object InterfaceAlias, IPAddress
}

$listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Host "[OK] Cong $port dang LISTEN, PID $($listener.OwningProcess)."
} else {
    Write-Host "[LOI] Khong co tien trinh lang nghe cong $port."
}

try {
    $local = Invoke-WebRequest "http://127.0.0.1:$port/api/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "[OK] Local HTTP tra ve $($local.StatusCode)."
} catch {
    Write-Host "[LOI] Local HTTP khong phan hoi: $($_.Exception.Message)"
}

try {
    $lan = Invoke-WebRequest "http://$expectedIp`:$port/api/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "[OK] LAN HTTP tra ve $($lan.StatusCode)."
} catch {
    Write-Host "[LOI] LAN HTTP khong phan hoi: $($_.Exception.Message)"
}

$rule = Get-NetFirewallRule -DisplayName "VNPost Device Inventory Web $port" -ErrorAction SilentlyContinue
if ($rule) {
    Write-Host "[OK] Co firewall rule, Enabled=$($rule.Enabled), Profile=$($rule.Profile)."
} else {
    Write-Host "[LOI] Chua co firewall rule. Chay allow_firewall_intranet.ps1 bang Administrator."
}

if (Test-Path $logPath) {
    Write-Host "=== 30 DONG LOG CUOI ==="
    Get-Content $logPath -Tail 30
}

<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0') -join [char]10)"
exit /b
#>

# URL GitHub Pages của ứng dụng rà soát thiết bị
$ServerUrl = "https://nguyennam90.github.io/Check_thiet_bi"

# 1. Thu thập dữ liệu phần cứng từ Windows WMI/CIM
Write-Host "Dang doc thong tin phan cung may tinh, vui long cho..." -ForegroundColor Cyan

$hostname = $env:COMPUTERNAME
$cpu      = Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name
$cs       = Get-CimInstance Win32_ComputerSystem | Select-Object -First 1
$bios     = Get-CimInstance Win32_BIOS | Select-Object -First 1
$os       = Get-CimInstance Win32_OperatingSystem | Select-Object -First 1
$disk     = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Measure-Object -Property Size -Sum
$adapter  = Get-CimInstance Win32_NetworkAdapterConfiguration |
              Where-Object { $_.IPEnabled -eq $true -and $_.IPAddress } |
              Select-Object -First 1

$manufacturer = $cs.Manufacturer.Trim()
$model        = $cs.Model.Trim()
$ram          = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$serial       = $bios.SerialNumber.Trim()
$os_name      = $os.Caption
$os_version   = $os.Version
$disk_size    = [math]::Round($disk.Sum / 1GB, 0)
$ip           = ($adapter.IPAddress | Where-Object { $_ -match '^\d+\.' } | Select-Object -First 1)
$mac          = $adapter.MACAddress
$machineType  = if ($cs.PCSystemType -eq 2) { "Laptop" } else { "Desktop" }

$office = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match "Microsoft 365|Microsoft Office" } |
    Select-Object -First 1 -ExpandProperty DisplayName

$antivirus = Get-CimInstance `
    -Namespace "root\SecurityCenter2" `
    -ClassName AntiVirusProduct `
    -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty displayName

# 2. Chuẩn hóa chuỗi tham số (URL-encode)
Add-Type -AssemblyName System.Web
function Encode-Param($val) {
    if ($null -eq $val) { return "" }
    return [System.Web.HttpUtility]::UrlEncode($val.ToString())
}

$params = @(
    "hostname=$(Encode-Param $hostname)",
    "cpu=$(Encode-Param $cpu)",
    "hang=$(Encode-Param $manufacturer)",
    "model=$(Encode-Param $model)",
    "ram=$(Encode-Param ($ram.ToString() + ' GB'))",
    "disk=$(Encode-Param ($disk_size.ToString() + ' GB'))",
    "serial=$(Encode-Param $serial)",
    "os=$(Encode-Param ($os_name + ' ' + $os_version))",
    "ip=$(Encode-Param $ip)",
    "mac=$(Encode-Param $mac)",
    "loaiMay=$(Encode-Param $machineType)",
    "office=$(Encode-Param $office)",
    "antivirus=$(Encode-Param ($antivirus -join ', '))"
)

# 3. Tạo URL hoàn chỉnh và mở trình duyệt mặc định
$targetUrl = "$ServerUrl/?" + ($params -join "&")
Write-Host "Hoan thanh! Dang mo trinh duyet..." -ForegroundColor Green

Start-Process $targetUrl

param(
    [string]$ServerUrl = "https://nguyennam90.github.io/Check_thiet_bi"
)

# Xóa dấu / cuối nếu có
$ServerUrl = $ServerUrl.TrimEnd("/")

$logDirectory = Join-Path $env:LOCALAPPDATA "VNPostDeviceInventory"
$logPath      = Join-Path $logDirectory "client_collector.log"

function Write-CollectorLog([string]$message) {
    try {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        Add-Content -LiteralPath $logPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
    } catch { }
}

function First-Value($value) {
    return @($value | Where-Object { $_ }) | Select-Object -First 1
}

try {
    Write-CollectorLog "Starting collection for $env:COMPUTERNAME."

    $cpu      = Get-CimInstance Win32_Processor | Select-Object -First 1
    $computer = Get-CimInstance Win32_ComputerSystem | Select-Object -First 1
    $bios     = Get-CimInstance Win32_BIOS | Select-Object -First 1
    $os       = Get-CimInstance Win32_OperatingSystem | Select-Object -First 1
    $disks    = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $adapter  = Get-CimInstance Win32_NetworkAdapterConfiguration |
                  Where-Object { $_.IPEnabled -eq $true -and $_.IPAddress } |
                  Select-Object -First 1

    $diskTotal  = ($disks | Measure-Object -Property Size -Sum).Sum
    $ramGb      = if ($computer.TotalPhysicalMemory) { [math]::Round($computer.TotalPhysicalMemory / 1GB, 1) } else { $null }
    $diskGb     = if ($diskTotal) { [math]::Round($diskTotal / 1GB, 0) } else { $null }
    $ipAddress  = First-Value ($adapter.IPAddress | Where-Object { $_ -match "^\d+\." })
    $machineType = if ($computer.PCSystemType -eq 2) { "Laptop" } else { "Desktop" }

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

    # URL-encode các tham số rồi mở trình duyệt với GitHub Pages URL
    Add-Type -AssemblyName System.Web
    function Encode-Param($val) {
        if ($null -eq $val) { return "" }
        return [System.Web.HttpUtility]::UrlEncode($val.ToString())
    }

    $ramStr  = if ($ramGb)  { "$ramGb GB" }  else { "" }
    $diskStr = if ($diskGb) { "$diskGb GB" } else { "" }
    $osStr   = "$($os.Caption) $($os.Version)".Trim()
    $avStr   = ($antivirus -join ", ")

    $params = @(
        "hostname=$(Encode-Param $env:COMPUTERNAME)",
        "cpu=$(Encode-Param $cpu.Name)",
        "hang=$(Encode-Param $computer.Manufacturer)",
        "model=$(Encode-Param $computer.Model)",
        "ram=$(Encode-Param $ramStr)",
        "disk=$(Encode-Param $diskStr)",
        "serial=$(Encode-Param $bios.SerialNumber)",
        "os=$(Encode-Param $osStr)",
        "ip=$(Encode-Param $ipAddress)",
        "mac=$(Encode-Param $adapter.MACAddress)",
        "loaiMay=$(Encode-Param $machineType)",
        "office=$(Encode-Param $office)",
        "antivirus=$(Encode-Param $avStr)"
    )

    $targetUrl = "$ServerUrl/?" + ($params -join "&")
    Start-Process $targetUrl
    Write-CollectorLog "Opened browser with device info URL."

} catch {
    $errorMessage = $_.Exception.Message
    Write-CollectorLog "Collection failed: $errorMessage"
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        [System.Windows.MessageBox]::Show(
            "Khong the lay thong tin may.`n`n$errorMessage",
            "VNPost - Thu thap thong tin may",
            "OK",
            "Error"
        ) | Out-Null
    } catch { }
    exit 1
}

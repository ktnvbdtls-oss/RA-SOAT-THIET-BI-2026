param(
    [string]$ServerUrl = "http://10.43.128.10:8789"
)

$ErrorActionPreference = "Stop"
$ServerUrl = $ServerUrl.TrimEnd("/")
$logDirectory = Join-Path $env:ProgramData "VNPostDeviceInventory"
$logPath = Join-Path $logDirectory "managed_client_agent.log"

function Write-AgentLog([string]$message) {
    try {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        Add-Content -LiteralPath $logPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
    } catch {
        # Logging must not stop inventory collection.
    }
}

function First-Value($value) {
    return @($value | Where-Object { $_ }) | Select-Object -First 1
}

try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $computer = Get-CimInstance Win32_ComputerSystem | Select-Object -First 1
    $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
    $os = Get-CimInstance Win32_OperatingSystem | Select-Object -First 1
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $adapter = Get-CimInstance Win32_NetworkAdapterConfiguration |
        Where-Object { $_.IPEnabled -eq $true -and $_.IPAddress } |
        Select-Object -First 1

    $diskTotal = ($disks | Measure-Object -Property Size -Sum).Sum
    $ramGb = if ($computer.TotalPhysicalMemory) {
        [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
    } else {
        $null
    }
    $diskGb = if ($diskTotal) {
        [math]::Round($diskTotal / 1GB, 0)
    } else {
        $null
    }

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

    $machineType = if ($computer.PCSystemType -eq 2) { "Laptop" } else { "Desktop" }
    $ipAddress = First-Value ($adapter.IPAddress | Where-Object { $_ -match "^\d+\." })

    # ASCII-only source keeps compatibility with Windows PowerShell 5.1.
    $labels = @'
{
  "hostname": "T\u00ean m\u00e1y (Hostname)",
  "machineType": "Lo\u1ea1i m\u00e1y",
  "manufacturer": "H\u00e3ng",
  "disk": "\u1ed4 c\u1ee9ng",
  "operatingSystem": "H\u1ec7 \u0111i\u1ec1u h\u00e0nh"
}
'@ | ConvertFrom-Json

    $fields = [ordered]@{}
    $fields[$labels.hostname] = $env:COMPUTERNAME
    $fields[$labels.machineType] = $machineType
    $fields[$labels.manufacturer] = $computer.Manufacturer
    $fields["Model"] = $computer.Model
    $fields["Serial Number"] = $bios.SerialNumber
    $fields["CPU"] = $cpu.Name
    $fields["RAM"] = if ($ramGb) { "$ramGb GB" } else { "" }
    $fields[$labels.disk] = if ($diskGb) { "$diskGb GB" } else { "" }
    $fields[$labels.operatingSystem] = "$($os.Caption) $($os.Version)".Trim()
    $fields["Office"] = $office
    $fields["Antivirus"] = ($antivirus -join ", ")
    $fields["IP Address"] = $ipAddress
    $fields["MAC Address"] = $adapter.MACAddress

    $payload = @{
        machineId = "$env:COMPUTERNAME|$($bios.SerialNumber)"
        fields = $fields
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod `
        -Uri "$ServerUrl/api/client-inventory" `
        -Method Post `
        -ContentType "application/json; charset=utf-8" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($payload)) `
        -TimeoutSec 30 | Out-Null

    Write-AgentLog "Inventory sent for $env:COMPUTERNAME."
} catch {
    $errorMessage = "Inventory failed: $($_.Exception.Message)"
    Write-AgentLog $errorMessage
    Write-Error $errorMessage
    exit 1
}

param(
    [Parameter(Mandatory = $true)]
    [string[]]$ComputerName,
    [string]$ServerUrl = "http://10.43.128.10:8789"
)

$ErrorActionPreference = "Stop"
$sourceDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceAgent = Join-Path $sourceDirectory "managed_client_agent.ps1"
$sourceInstaller = Join-Path $sourceDirectory "install_managed_client_agent.ps1"

foreach ($path in @($sourceAgent, $sourceInstaller)) {
    if (-not (Test-Path $path)) {
        throw "Khong tim thay file: $path"
    }
}

$results = foreach ($computer in $ComputerName) {
    $session = $null
    try {
        Write-Host "Dang trien khai agent den $computer ..."
        $session = New-PSSession -ComputerName $computer
        $remoteDirectory = Invoke-Command -Session $session -ScriptBlock {
            $path = Join-Path $env:ProgramData "VNPostDeviceInventory\Deployment"
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            return $path
        }

        Copy-Item -LiteralPath $sourceAgent -Destination $remoteDirectory -ToSession $session -Force
        Copy-Item -LiteralPath $sourceInstaller -Destination $remoteDirectory -ToSession $session -Force

        Invoke-Command -Session $session -ScriptBlock {
            param($directory, $url)
            & (Join-Path $directory "install_managed_client_agent.ps1") -ServerUrl $url
        } -ArgumentList $remoteDirectory, $ServerUrl

        [pscustomobject]@{
            Computer = $computer
            Status = "Thanh cong"
            Detail = ""
        }
    } catch {
        [pscustomobject]@{
            Computer = $computer
            Status = "That bai"
            Detail = $_.Exception.Message
        }
    } finally {
        if ($session) {
            Remove-PSSession $session
        }
    }
}

$results | Format-Table -AutoSize

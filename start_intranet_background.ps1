$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $root "run_intranet_server.ps1"
$pidPath = Join-Path $root "data\intranet-server.pid"
$logPath = Join-Path $root "logs\intranet-server.log"
$port = 8789

if (Test-Path $pidPath) {
    $existingPid = (Get-Content $pidPath -Raw).Trim()
    if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
        Write-Host "Server dang chay voi PID $existingPid."
        Write-Host "URL: http://10.43.128.10:$port/"
        exit 0
    }
    Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
}

$listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Host "Cong $port dang duoc tien trinh PID $($listener.OwningProcess) su dung."
    Write-Host "Khong khoi dong them server."
    exit 1
}

if (Test-Path $logPath) {
    $previousLog = Join-Path (Split-Path -Parent $logPath) "intranet-server.previous.log"
    Move-Item -LiteralPath $logPath -Destination $previousLog -Force
}

$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$runner`""
$process = Start-Process `
    -FilePath "powershell.exe" `
    -ArgumentList $arguments `
    -WorkingDirectory $root `
    -WindowStyle Hidden `
    -PassThru

$ready = $false
$lastError = ""

for ($attempt = 1; $attempt -le 30; $attempt++) {
    Start-Sleep -Seconds 1
    $process.Refresh()
    if ($process.HasExited) {
        $lastError = "Tien trinh server da thoat (ExitCode=$($process.ExitCode))."
        break
    }

    $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if (-not $listener) {
        continue
    }

    try {
        $response = Invoke-WebRequest `
            "http://127.0.0.1:$port/api/health" `
            -UseBasicParsing `
            -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        $lastError = $_.Exception.Message
    }
}

if ($ready) {
    Write-Host "Server da chay nen voi PID $($process.Id)."
    Write-Host "Local: http://127.0.0.1:$port/"
    Write-Host "LAN:   http://10.43.128.10:$port/"
    Write-Host "Dong cua so nay khong lam dung server."
    exit 0
}

Write-Host "Server chua san sang sau 30 giay."
if ($lastError) {
    Write-Host "Chi tiet: $lastError"
}
Write-Host "Kiem tra log:"
Write-Host $logPath
Write-Host "Chay foreground de xem loi:"
Write-Host "powershell -NoProfile -ExecutionPolicy Bypass -File `"$runner`""
if (Test-Path $logPath) {
    Get-Content $logPath -Tail 50
}
exit 1

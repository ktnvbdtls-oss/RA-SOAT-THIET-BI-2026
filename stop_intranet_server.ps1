$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidPath = Join-Path $root "data\intranet-server.pid"
$port = 8789
$pids = @()

if (Test-Path $pidPath) {
    $savedPid = (Get-Content $pidPath -Raw).Trim()
    if ($savedPid) {
        $pids += [int]$savedPid
    }
}

$listeners = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
$pids += @($listeners | Select-Object -ExpandProperty OwningProcess)
$pids = @($pids | Where-Object { $_ } | Select-Object -Unique)

if (-not $pids.Count) {
    Write-Host "Khong tim thay server dang chay tren cong $port."
} else {
    foreach ($processId in $pids) {
        taskkill /PID $processId /T /F | Out-Null
        Write-Host "Da dung cay tien trinh PID $processId."
    }
}

Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue

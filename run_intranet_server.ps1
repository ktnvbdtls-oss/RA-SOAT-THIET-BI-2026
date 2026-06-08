$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $root "logs"
$logPath = Join-Path $logDir "intranet-server.log"
$pidPath = Join-Path $root "data\intranet-server.pid"
$pythonPathFile = Join-Path $root "data\python-path.txt"

New-Item -ItemType Directory -Force -Path $logDir, (Split-Path -Parent $pidPath) | Out-Null

$writeTest = Join-Path $root "data\.write-test"
try {
    Set-Content -Path $writeTest -Value "ok" -Encoding ASCII
    Remove-Item -LiteralPath $writeTest -Force
} catch {
    throw "Thu muc ung dung khong co quyen ghi: $root. Hay cap quyen Modify cho tai khoan chay server."
}

function Resolve-Python {
    if ($env:DEVICE_INVENTORY_PYTHON -and (Test-Path $env:DEVICE_INVENTORY_PYTHON)) {
        return $env:DEVICE_INVENTORY_PYTHON
    }
    if (Test-Path $pythonPathFile) {
        $saved = (Get-Content $pythonPathFile -Raw).Trim()
        if ($saved -and (Test-Path $saved)) {
            return $saved
        }
    }

    $candidates = @(
        (Join-Path $root "runtime\python\python.exe"),
        (Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"),
        "C:\Program Files\Python313\python.exe",
        "C:\Program Files\Python312\python.exe",
        "C:\Program Files\Python311\python.exe",
        "C:\Program Files\Python310\python.exe"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    $command = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    throw "Khong tim thay Python. Hay cai Python 3.10+ va openpyxl."
}

$python = Resolve-Python
Set-Content -Path $pythonPathFile -Value $python -Encoding UTF8
Set-Content -Path $pidPath -Value $PID -Encoding ASCII

$env:PYTHONIOENCODING = "utf-8"
$env:DEVICE_INVENTORY_HOST = "0.0.0.0"
$env:DEVICE_INVENTORY_PORT = "8789"
$env:DEVICE_INVENTORY_DATA_ROOT = $root

if (-not $env:DEVICE_INVENTORY_ADMIN_PASSWORD) {
    $env:DEVICE_INVENTORY_ADMIN_PASSWORD = "250389"
}

Set-Location $root

try {
    "[$(Get-Date -Format s)] Starting intranet server with Python: $python" |
        Add-Content -Path $logPath -Encoding UTF8
    & $python -B (Join-Path $root "server.py") *>> $logPath
} catch {
    "[$(Get-Date -Format s)] $($_.Exception.Message)" | Add-Content -Path $logPath -Encoding UTF8
    throw
} finally {
    Remove-Item -LiteralPath $pidPath -Force -ErrorAction SilentlyContinue
}

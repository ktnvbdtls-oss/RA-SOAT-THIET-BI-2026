$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bundledPython = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
$python = if (Test-Path $bundledPython) { $bundledPython } else { "python" }
$env:PYTHONIOENCODING = "utf-8"
Set-Location $root
& $python -B (Join-Path $root "server.py")

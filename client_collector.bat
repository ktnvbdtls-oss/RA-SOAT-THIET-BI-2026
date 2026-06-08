@echo off
cd /d "%~dp0"
if exist "%~dp0client_collector.vbs" (
    start "" /b wscript.exe "%~dp0client_collector.vbs"
) else (
    start "" /b powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0client_collector.ps1"
)
exit /b 0

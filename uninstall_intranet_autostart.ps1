$ErrorActionPreference = "Stop"

$taskName = "VNPost Device Inventory Web"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Da go Task Scheduler: $taskName"
} else {
    Write-Host "Khong tim thay Task Scheduler: $taskName"
}

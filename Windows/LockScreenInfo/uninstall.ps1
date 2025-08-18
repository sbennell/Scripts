#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Uninstalls LockScreenInfo: removes scheduled task, files, registry key, and logs actions.
#>

# --- Variables ---
$Destination = "C:\Windows\OEMFiles\Script\LockScreenInfo"
$RegPath     = "HKLM:\Software\SOE\LockScreenInfo"
$TaskName    = "LockScreenInfo"
$LogFolder   = "C:\Windows\OEMFiles\logs"
$LogFile     = Join-Path $LogFolder "LockScreenInfo_Uninstall.log"

# --- Logging helper ---
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = "$timestamp - $Message"
    Write-Host $fullMessage -ForegroundColor Yellow

    if (-not (Test-Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }
    Add-Content -Path $LogFile -Value $fullMessage
}

Write-Log "Starting LockScreenInfo uninstall process..."

# --- Remove Scheduled Task ---
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Log "Removed scheduled task: $TaskName"
} else {
    Write-Log "Scheduled task not found: $TaskName"
}

# --- Remove Installed Files ---
if (Test-Path $Destination) {
    Remove-Item -Path $Destination -Recurse -Force
    Write-Log "Removed folder and files: $Destination"
} else {
    Write-Log "Destination folder not found: $Destination"
}

# --- Remove Registry Key ---
if (Test-Path $RegPath) {
    Remove-Item -Path $RegPath -Recurse -Force
    Write-Log "Removed registry key: $RegPath"
} else {
    Write-Log "Registry key not found: $RegPath"
}

Write-Log "LockScreenInfo uninstall process complete."

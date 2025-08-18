#Requires -RunAsAdministrator

# Uninstall script for LockScreenInfo deployment
$ErrorActionPreference = "Continue"
$LogPath = "C:\Windows\OEMFiles\logs\LockScreenInfo_Uninstall.log"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogPath -Append
    Write-Host $Message
}

try {
    Write-Log "Starting LockScreenInfo uninstallation..."
    
    # Remove scheduled task
    $TaskName = "LockScreenInfo"
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Log "Removed scheduled task: $TaskName"
    } else {
        Write-Log "Scheduled task $TaskName not found"
    }
    
    # Remove OEMFiles directory (optional - you might want to keep wallpapers)
    $OEMPath = "C:\Windows\OEMFiles"
    if (Test-Path $OEMPath) {
        # Remove only our specific files/folders, but preserve logs for troubleshooting
        $PathsToRemove = @(
            "$OEMPath\Scripts\LockScreenInfo",
        )
        
        foreach ($path in $PathsToRemove) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction Continue
                Write-Log "Removed: $path"
            }
        }
        
        Write-Log "Note: Logs preserved in $OEMPath\logs for troubleshooting"
    }
    
    Write-Log "LockScreenInfo uninstallation completed"
    exit 0
    
} catch {
    Write-Log "Uninstallation error: $($_.Exception.Message)"
    exit 1
}
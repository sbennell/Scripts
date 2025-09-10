# Requirement-NoRestartPending.ps1
# Intune Win32 App Requirement Rule Script
# Checks if system is ready for installation (no restart pending)
# Returns: Exit 0 + STDOUT string if requirements met, Exit 1 if requirements NOT met

try {
    $restartRequired = $false
    $reasons = @()
    
    # Check 1: Windows Update restart pending
    $auRebootRequired = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
    if ($auRebootRequired) {
        $restartRequired = $true
        $reasons += "Windows Update restart pending"
    }
    
    # Check 2: Component Based Servicing restart pending
    $cbsRebootPending = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
    if ($cbsRebootPending) {
        $restartRequired = $true
        $reasons += "Component servicing restart pending"
    }
    
    # Check 3: Pending file rename operations
    $pendingFileRename = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
    if ($pendingFileRename -and $pendingFileRename.PendingFileRenameOperations) {
        $restartRequired = $true
        $reasons += "File rename operations pending"
    }
    
    # Check 4: Windows Installer restart pending
    $installerRestart = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\InProgress" -ErrorAction SilentlyContinue
    if ($installerRestart) {
        $restartRequired = $true
        $reasons += "Windows Installer restart pending"
    }
    
    # Check 5: System uptime validation (optional - uncomment if needed)
    # $uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    # $uptimeDays = [math]::Round($uptime.TotalDays, 2)
    # if ($uptimeDays -gt 7) {
    #     $restartRequired = $true
    #     $reasons += "System uptime exceeds 7 days ($uptimeDays days)"
    # }
    
    # Check 6: Configuration Manager restart pending (if SCCM present)
    try {
        $ccmClientSDK = Get-WmiObject -Namespace "ROOT\ccm\ClientSDK" -Class "CCM_ClientUtilities" -ErrorAction SilentlyContinue
        if ($ccmClientSDK) {
            $pendingReboot = $ccmClientSDK.DetermineIfRebootPending()
            if ($pendingReboot -and $pendingReboot.RebootPending) {
                $restartRequired = $true
                $reasons += "Configuration Manager restart pending"
            }
        }
    }
    catch {
        # SCCM not present or accessible, continue without this check
    }
    
    # Evaluate results for requirement rule
    if ($restartRequired) {
        # REQUIREMENT NOT MET - system needs restart before installation
        # Exit 1 means requirement fails, installation will be blocked/postponed
        exit 1
    }
    else {
        # REQUIREMENT MET - system is ready for installation
        # Exit 0 + STDOUT string means requirement passes, installation can proceed
        $uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        $uptimeDays = [math]::Round($uptime.TotalDays, 2)
        
        Write-Output "System ready for installation - uptime: $uptimeDays days, no restart pending"
        exit 0
    }
}
catch {
    # On error, assume requirement is not met (safer approach)
    # This prevents installation if we can't properly evaluate system state
    exit 1
}

# End of requirement script
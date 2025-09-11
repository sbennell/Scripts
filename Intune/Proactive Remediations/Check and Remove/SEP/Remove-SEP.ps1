# Quick fix for the original Remove-SEP.ps1
$LogFile = "$env:ProgramData\SEP_Uninstall.log"
Function Write-Log {
    param([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'u') - $Message"
}

Write-Log "Starting SEP uninstall remediation."

$SEP = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" ,
                     "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -like "Symantec Endpoint Protection*" }

if ($SEP) {
    $ProductCode = $SEP.PSChildName
    Write-Log "Found SEP Product Code: $ProductCode"
    try {
        # Fix: Remove extra braces and add proper parameters
        $CleanProductCode = $ProductCode -replace "[{}]", ""
        $Arguments = "/x{$CleanProductCode} /qn /norestart REBOOT=SUPPRESS"
        Write-Log "Executing: msiexec.exe $Arguments"
        
        $Process = Start-Process "msiexec.exe" -ArgumentList $Arguments -Wait -PassThru
        Write-Log "Uninstall completed with exit code: $($Process.ExitCode)"
        
        if ($Process.ExitCode -eq 0) {
            Write-Log "Uninstall successful"
        } else {
            Write-Log "Uninstall may have failed - Exit code: $($Process.ExitCode)"
        }
    } catch {
        Write-Log "Error uninstalling SEP: $_"
    }
} else {
    Write-Log "No SEP found during remediation."
}

Write-Log "SEP remediation script finished."
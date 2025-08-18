#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Detection script for Intune to check if LockScreenInfo is installed.
    Detects any version >= $RequiredVersion.
#>

$Destination      = "C:\Windows\OEMFiles\Script\LockScreenInfo"
$RegPath          = "HKLM:\Software\SOE\LockScreenInfo"
$RegName          = "Version"
$RequiredVersion  = [version]"1.3.1"  # Minimum required version

# --- Check Registry ---
$RegInstalled = $false
if (Test-Path $RegPath) {
    try {
        $InstalledVersion = [version](Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction Stop).$RegName
        if ($InstalledVersion -ge $RequiredVersion) {
            $RegInstalled = $true
        }
    } catch {
        $RegInstalled = $false
    }
}

# --- Check Folder ---
$FolderExists = Test-Path $Destination

# --- Detection Result ---
if ($RegInstalled -and $FolderExists) {
    Write-Output "Installed (Version $InstalledVersion)"
    exit 0  # Success: installed
} else {
    Write-Output "Not Installed or Version too low"
    exit 1  # Failure: not installed
}

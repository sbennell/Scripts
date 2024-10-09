# // ***************************************************************************
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // File:      Install-WindowsUpdates.ps1
# // 
# // Version:   09.10.24-03
# //
# // Version History
# // 25.01.24-01: Initial version
# // 20.08.24-02: Revised to not run between 08:30-15:30 on excluded gateways for schools with shaped internet Connect to microsoft
# // 09.10.24-03: Add Logging for debug
# // 09.10.24-04: Refined default gateway retrieval using WMI and improved logging structure
# // 
# // Purpose:   Running Windows updates During Deployment.
# // 
# // ***************************************************************************

# Define the gateway IPs to Check time
$excludedGateways = @("10.140.44.1", "10.142.196.1")

# Define the time range
$startTime = [datetime]::Parse("08:30:00")
$endTime = [datetime]::Parse("15:30:00")

# MDT environment setup
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$DeployShare = $TSEnv.Value("DeployRoot")
$OSDComputerName = $TSEnv.Value("OSDComputerName")
$logFile = "$DeployShare\Logs\$($OSDComputerName)\Install-WindowsUpdates_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"

# Ensure log directory exists
if (-not (Test-Path -Path (Split-Path $logFile))) {
    New-Item -ItemType Directory -Path (Split-Path $logFile) -Force
}

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path "$logFile" -Value "$timestamp - $message"
}

# Function to get the default gateway
function Get-DefaultGateway {
    $gateway = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -and $_.DefaultIPGateway }) | Select-Object -First 1 -ExpandProperty DefaultIPGateway
    
    if ([string]::IsNullOrEmpty($gateway)) {
        Log-Message "No default gateway found."
        return $null
    } else {
        return $gateway
    }
}

# Function to check if the current time is outside a specified range
function Is-TimeOutsideRange {
    param (
        [datetime]$startTime,
        [datetime]$endTime
    )
    
    $currentTime = Get-Date
    return $currentTime -lt $startTime -or $currentTime -gt $endTime
}

# Function to Perform Updates
function Perform-Updates {
    try {
        Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.208 -Force
        Log-Message "Installed NuGet provider successfully."
    } catch {
        Log-Message "Failed to install NuGet provider: $_"
        exit 1
    }

    Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"

    if (-not (Get-Module -ListAvailable -Name "PSWindowsUpdate")) {
        Install-Module -Name "PSWindowsUpdate" -Force
        Log-Message "Installed PSWindowsUpdate module."
    }

    Import-Module -Name "PSWindowsUpdate" -ErrorAction Stop

    try {
        Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -NotCategory "Drivers" -IgnoreReboot
        Log-Message "Windows updates installed."
    } catch {
        Log-Message "Failed to install Windows updates: $_"
    }
}

# Get the default gateway
$defaultGateway = Get-DefaultGateway

# Check if the default gateway is missing
if ($defaultGateway -eq $null) {
    Log-Message "No default gateway detected. Skipping updates."
    exit 1
}


# Log current gateway and time
Log-Message "Current Default Gateway: $defaultGateway, Current Time: $(Get-Date -Format 'HH:mm:ss')"

# Check for internet connectivity
$netConnectionProfile = Get-NetConnectionProfile
if ($netConnectionProfile.IPv4Connectivity -eq "Internet" -or $netConnectionProfile.IPv6Connectivity -eq "Internet") {
    # Check if the default gateway is in the excluded list
    if ($excludedGateways -contains $defaultGateway) {
        Log-Message "Current gateway ($defaultGateway) is excluded list. Proceeding with time Check."
        # Check if the time is outside the prohibited range
        if (Is-TimeOutsideRange -startTime $startTime -endTime $endTime) {
            Log-Message "Current time is outside the prohibited range. Proceeding with updates."
            Perform-Updates
        } else {
            Log-Message "Current time is within the prohibited range. Skipping updates."
        }
    } else {
        Log-Message "Current gateway ($defaultGateway) and is not in excluded list so will run updates."
		Perform-Updates
    }
} else {
    Log-Message "No internet connection detected."
}
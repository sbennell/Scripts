# // ***************************************************************************
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // File:      Copy-Drivers.ps1
# // 
# // Version:   9.10.24-03
# // Version History
# // 25.01.24-01: Initial version
# // 20.08.24-02: Revised to not run between 08:30-15:30 on excluded gateways
# // 09.10.24-03: Add Logging for debug
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
$logFile = "$DeployShare\Logs\$($OSDComputerName)\Copy-Drivers_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"

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
    $gateway = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixLength -eq 0 } | Select-Object -ExpandProperty DefaultGateway)
    return $gateway
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

# Log current gateway and time
Log-Message "Current Default Gateway: $defaultGateway, Current Time: $(Get-Date -Format 'HH:mm:ss')"

# Check for internet connectivity
$netConnectionProfile = Get-NetConnectionProfile
if ($netConnectionProfile.IPv4Connectivity -eq "Internet" -or $netConnectionProfile.IPv6Connectivity -eq "Internet") {
    # Check if the default gateway is in the excluded list
    if ($excludedGateways -contains $defaultGateway) {
        Log-Message "Current gateway ($defaultGateway) is excluded. Proceeding with updates."
        Perform-Updates
    } else {
        Log-Message "Current gateway ($defaultGateway) requires time check."
        # Check if the time is outside the prohibited range
        if (Is-TimeOutsideRange -startTime $startTime -endTime $endTime) {
            Log-Message "Current time is outside the prohibited range. Proceeding with updates."
            Perform-Updates
        } else {
            Log-Message "Current time is within the prohibited range. Skipping updates."
        }
    }
} else {
    Log-Message "No internet connection detected."
}

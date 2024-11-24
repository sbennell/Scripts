<#
.Synopsis
Created on:   2/08/2024
Updated on:   25/11/2024
Created by:   Stewart
Filename:     Install-Printer-Driver.ps1

Simple PowerShell Script to install a printer drivervia Microsoft Intune. Required files should be in the same directory as the script when creating a Win32 app for deployment via Intune.

### Powershell Commands ###

Install:
powershell.exe -ExecutionPolicy Bypass -File .\\Install-Printer-Driver.ps1 -DriverName "KONICA MINOLTA Universal PCL" -INFFile "KOAWUJ__.inf"

Detection:

Rule Type:          Registry
Key path:           HKLM:\SOFTWARE\IntuneDriversInstallation
Value:              KOAWUJ__.inf
Detection method:   String comparison
Operator:           Equals
Name:               1

.Example
..\Install-Printer-Driver.ps1 -DriverName "KONICA MINOLTA Universal V4 PCL" -INFFile "KOBxxK__01.inf"

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $True)]
    [String]$DriverName,
    [Parameter(Mandatory = $True)]
    [String]$INFFile,
    [Parameter(Mandatory = $False)]
    [String]$LogDirectory = "$env:TEMP"
)

# Reset Error variable
$Throwbad = $Null

# Function for logging
function Write-LogEntry {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $false)]
        [string]$FileName = "$($DriverName).log",
        [switch]$Stamp
    )

    # Build log file path
    $LogFile = Join-Path -Path $LogDirectory -ChildPath $FileName
    $Time = (Get-Date -Format "HH:mm:ss.fff")
    $Date = (Get-Date -Format "MM-dd-yyyy")
    $LogText = if ($Stamp) {
        "<$Value> <time='$Time' date='$Date'>"
    } else {
        $Value
    }

    # Attempt to write to the log
    try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFile -ErrorAction Stop
    } catch {
        Write-Warning "Unable to log entry to $LogFile. Error: $($_.Exception.Message)"
    }
}

# Validate INF file
if (-not (Test-Path -Path "$PSScriptRoot\$INFFile")) {
    Write-Error "The INF file '$INFFile' does not exist in the script directory."
    exit 1
}

# Validate registry permissions
try {
    $RegistryTest = Test-Path -Path HKLM:\SOFTWARE\IntuneDriversInstallation
    if (-not $RegistryTest) {
        New-Item -Path HKLM:\SOFTWARE -Name IntuneDriversInstallation -Force | Out-Null
    }
} catch {
    Write-Error "Insufficient permissions to modify registry at HKLM:\SOFTWARE\IntuneDriversInstallation."
    exit 1
}

# Log start
Write-LogEntry -Value "##################################"
Write-LogEntry -Stamp -Value "Installation started"
Write-LogEntry -Value "##################################"
Write-LogEntry -Value "Driver Name: $DriverName"
Write-LogEntry -Value "INF File: $INFFile"

# Set arguments for pnputil
$INFARGS = @("/add-driver", "$PSScriptRoot\$INFFile")

# Stage driver to Windows driver store
try {
    Write-LogEntry -Stamp -Value "Staging Driver to Windows Driver Store"
    Start-Process pnputil.exe -ArgumentList $INFARGS -Wait -PassThru | Out-Null
} catch {
    Write-Error "Failed to stage driver to driver store."
    Write-LogEntry -Stamp -Value "Error staging driver: $($_.Exception.Message)"
    $Throwbad = $True
}

# Install driver if no errors
if (-not $Throwbad) {
    try {
        $DriverExist = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
        if (-not $DriverExist) {
            Write-LogEntry -Stamp -Value "Installing Printer Driver: $DriverName"
            Add-PrinterDriver -Name $DriverName -Confirm:$false
            # Set Intune detection key
            Set-ItemProperty -Path HKLM:\SOFTWARE\IntuneDriversInstallation -Name $INFFile -Value 1 -Force
        } else {
            Write-LogEntry -Stamp -Value "Printer Driver '$DriverName' already exists. Skipping installation."
        }
    } catch {
        Write-Error "Error installing Printer Driver."
        Write-LogEntry -Stamp -Value "Error installing driver: $($_.Exception.Message)"
        $Throwbad = $True
    }
}

# Final cleanup and exit
if ($Throwbad) {
    Write-Error "Installation failed. Refer to the log file at $LogDirectory for details."
    Write-LogEntry -Stamp -Value "Installation failed."
    exit 1
} else {
    Write-LogEntry -Stamp -Value "Installation completed successfully."
}

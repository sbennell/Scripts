# // ***************************************************************************
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Solution Accelerator
# //
# // File:      Copy-Drivers.ps1
# // 
# // Version:   2024.10.4-3
# // Version History
# // 2024.3.14-2: Initial version
# // 2024.10.4-1: Get Make and Model from MDT
# // 2024.10.4-2: Improved error handling, fixed variable names, and added zip functionality Default commit out
# // 
# // Purpose:   Copy drivers from mounted drives' "DeployShare\Drivers" folder to the OSDisk's "Drivers" folder at deploy time.
# // 
# // ***************************************************************************

$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$DeployShare = $TSEnv.Value("DeployRoot")
$MAKE = $TSEnv.Value("MakeAlias")
$MODEL = $TSEnv.Value("ModelAlias")
[string] $driverDestination = "$DeployShare\Drivers"

function Convertto-SanitisedFolderName {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FolderName=$(Throw "Folder name required.")
    ) # End param

    ($FolderName -replace '[<>:"/\\|?*]', '_').TrimStart(" ").TrimEnd(". ")
}

Write-Output "Getting Computer Information..."
$Computer   = Get-WmiObject -Class Win32_ComputerSystem
$OSVersion  = [System.Environment]::OSVersion.Version
$OSName     = "Windows NFI"

# Determine OS Name based on OS Version
if ($OSVersion -ge [System.Version]"10.0.22000.0") {
    $OSName = "Windows 11"
} elseif ($OSVersion -ge [System.Version]"10.0.0.0") {
    $OSName = "Windows 10"
} elseif ($OSVersion -ge [System.Version]"6.2.0.0") {
    $OSName = "Windows 8"
} elseif ($OSVersion -ge [System.Version]"6.1.0.0") {
    $OSName = "Windows 7"
}

# Set up Driver Path
$DriverPath = "$driverDestination\$OSName\$MAKE\$MODEL"

if ($OSName -eq "Windows 7") {
    Write-Warning "Windows 7 is currently not supported with this script."
    Exit
}

# Error Handling: Safely Remove and Create Folders
try {
    if (Test-Path $DriverPath) {
        Remove-Item $DriverPath -Recurse -Force -ErrorAction Stop
    }
    New-Item -ItemType Directory -Path $DriverPath -Force -ErrorAction Stop
    Write-Output "Driver path created at $DriverPath."
} catch {
    Write-Error "Failed to create or clean driver directory: $($_.Exception.Message)"
    Exit
}

# Export and Organize Drivers
Write-Output "Extracting Windows Drivers to $DriverPath.."
try {
    $ExportedDrivers = Export-WindowsDriver -Online -Destination $DriverPath -ErrorAction Stop
    Write-Output "Drivers successfully exported."
} catch {
    Write-Error "Driver extraction failed: $($_.Exception.Message)"
    Exit
}

# Organizing Drivers into Subfolders
Write-Output "Organizing drivers into subfolders..."
foreach ($Driver in $ExportedDrivers) {
    $ParentFolder = Split-Path -Path (Split-Path -Path $Driver.OriginalFileName -Parent) -Leaf

    if ($Driver.ClassName -eq "Printer") {
        # Delete Printer Drivers
        try {
            Remove-Item "$DriverPath\$ParentFolder" -Recurse -Force -ErrorAction Stop
            Write-Output "Deleted printer driver: $ParentFolder."
        } catch {
            Write-Error "Failed to remove printer driver folder: $($_.Exception.Message)"
        }
    } else {
        # Organize Non-Printer Drivers
        $Destination  = "$DriverPath\$(Convertto-SanitisedFolderName $Driver.ClassName)\$(Convertto-SanitisedFolderName $Driver.ProviderName)"

        try {
            New-Item -ItemType Directory -Path $Destination -Force -ErrorAction Stop
            Move-Item "$DriverPath\$ParentFolder" $Destination -ErrorAction Stop
            Write-Output "Moved $ParentFolder to $Destination."
        } catch {
            Write-Error "Failed to move driver folder: $($_.Exception.Message)"
            Write-Output "Source: $DriverPath\$ParentFolder"
            Write-Output "Destination: $Destination"
            Write-Output "Driver Details: $Driver"
        }
    }
}

# Optional: Zip Compression
<# Write-Output "Checking for existing driver zip files..."
$DriverPathZip = "$driverDestination\$OSName\$MAKE\$MODEL.zip"

try {
    if (Test-Path $DriverPathZip) {
        Write-Output "Found existing zip file: $DriverPathZip. Removing..."
        Remove-Item $DriverPathZip -Force -ErrorAction Stop
    }

    Write-Output "Compressing drivers to $DriverPathZip..."
    Compress-Archive -Path "$DriverPath\*" -DestinationPath $DriverPathZip -ErrorAction Stop
    Write-Output "Drivers compressed successfully to $DriverPathZip."
} catch {
    Write-Error "Compression failed: $($_.Exception.Message)"
} #>

Write-Output "Script Complete."
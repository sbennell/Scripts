# // ***************************************************************************
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Powershell Scripts
# //
# // File:      Copy-Drivers.ps1
# // 
# // Version:   2024.10.5-5
# // 
# // Version History
# // 2024.3.14-3: Initial version
# // 2024.10.4-1: Grub make and model from MDT  
# // 2024.10.4-2: Improved error handling, Logging: Changed Write-Host to Write-Output 
# // 2024.10.4-3: Added fallback to base driver zip if specific drivers not found
# // 2024.10.4-4: Added logging to a file using Start-Transcript
# // 2024.10.5-5: Fixed Logging save location.
# // 
# // Purpose:   Copy drivers from mounted drives' "DeployShare\Drivers" folder to the OSDisk's "Drivers" folder at deploy time. If no specific drivers for the make and model are found, fallback to a base driver package.
# // 
# // ***************************************************************************

# MDT environment setup
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$OS = $TSEnv.Value("OS")
$DeployShare = $TSEnv.Value("DeployRoot")
$OSDriveLetter = $TSEnv.Value("OSDisk")
$MAKE = $TSEnv.Value("MakeAlias")
$MODEL = $TSEnv.Value("ModelAlias")
$OSDComputerName = $TSEnv.Value("OSDComputerName")
$driverDestination = "$OSDriveLetter\Drivers"
$driverSource = "$DeployShare\Drivers\$OS\$MAKE\$MODEL"
$driverSourcezip = "$DeployShare\Drivers\$OS\$MAKE\$MODEL.zip"
$basedriver = "$DeployShare\Drivers\$OS\basedriver.zip"  # Base driver fallback path
$destination = "$OSDriveLetter\Drivers\Custom\"

# Define the log file with timestamp
$logFile = "$DeployShare\Logs\$($OSDComputerName)\Copy-Drivers_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"

# Start logging to the log file
Start-Transcript -Path $logFile -Append -Force

# Create destination \Drivers directory and mark as hidden, if it doesn't already exist
try {
    if (-not (Test-Path $driverDestination)) {
        Write-Output "Creating hidden driver destination directory: ""$driverDestination""."
        $newDirectory = New-Item $driverDestination -ItemType Directory -ErrorAction Stop
        $newDirectory.Attributes += 'Hidden'
    }
} catch {
    Write-Error "Failed to create or set attributes for the destination directory: $($_.Exception.Message)"
    Stop-Transcript
    Exit
}

# Extract or copy driver content from specific driver sources or fallback to basedriver
try {
    if (Test-Path $driverSourcezip) {
        Write-Output "Extracting drivers from ""$driverSourcezip"" to ""$destination""."
        Expand-Archive -LiteralPath "$driverSourcezip" -DestinationPath "$destination" -ErrorAction Stop
        Write-Output "Drivers extracted successfully."
    } elseif (Test-Path $driverSource) {
        Write-Output "Copying drivers from ""$driverSource"" to ""$destination""."
        Copy-Item -Path $driverSource -Destination $destination -Recurse -ErrorAction Stop
        Write-Output "Drivers copied successfully."
    } elseif (Test-Path $basedriver) {
        Write-Output "Specific drivers not found. Extracting base driver package from ""$basedriver"" to ""$destination""."
        Expand-Archive -LiteralPath "$basedriver" -DestinationPath "$destination" -ErrorAction Stop
        Write-Output "Base drivers extracted successfully."
    } else {
        Write-Output "No specific or base drivers found at ""$driverSource"", ""$driverSourcezip"", or ""$basedriver""."
    }
} catch {
    Write-Error "An error occurred during the driver extraction or copy: $($_.Exception.Message)"
    Stop-Transcript
    Exit
}

Write-Output "Script complete. Exiting."

# Stop logging
Stop-Transcript
Exit
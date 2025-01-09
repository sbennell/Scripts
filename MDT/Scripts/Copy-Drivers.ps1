# // ***************************************************************************
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Powershell Scripts
# //
# // File:      Copy-Drivers.ps1
# // 
# // Version:   2024.12.3-6
# // 
# // Version History
# // 2024.3.14-3: Initial version
# // 2024.10.4-1: Grub make and model from MDT  
# // 2024.10.4-2: Improved error handling, Logging: Changed Write-Host to Write-Output 
# // 2024.10.4-3: Added fallback to base driver zip if specific drivers not found
# // 2024.10.4-4: Added logging to a file 
# // 2024.10.5-5: Fixed Logging save location.
# // 2024.12.3-6: Script now get make and model.
# // 
# // Purpose:   Copy drivers from mounted drives' "DeployShare\Drivers" folder to the OSDisk's "Drivers" folder at deploy time. If no specific drivers for the make and model are found, fallback to a base driver package.
# // 
# // ***************************************************************************

# MDT environment setup
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$OS = $TSEnv.Value("OS")
$DeployShare = $TSEnv.Value("DeployRoot")
$OSDriveLetter = $TSEnv.Value("OSDisk")
$OSDComputerName = $TSEnv.Value("OSDComputerName")

# Function to find the drive that contains the "MININT\SMSOSD\OSDLOGS" folder
function Find-LogDirectory {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -and (Test-Path $_.Root) }

    foreach ($drive in $drives) {
        $logFolderPath = Join-Path -Path $drive.Root -ChildPath "MININT\SMSOSD\OSDLOGS"
        if (Test-Path $logFolderPath) {
            return $logFolderPath
        }
    }

    # If the folder is not found, return $null
    return $null
}

# Find the correct log folder path
$logDirectory = Find-LogDirectory

# Check if the log directory was found
if ($logDirectory -eq $null) {
    Write-Host "The directory MININT\SMSOSD\OSDLOGS was not found on any drive."
    exit 1
}

# Set the log file path in the correct directory
$logFile = Join-Path -Path $logDirectory -ChildPath "Copy-Drivers.log"

# Function to log messages to the log file
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

function Get-MakeModel {
	Log-Message "Start function for get make/model."

	# Get the manufacturer (make) of the system from BIOS
	$systemInfo = Get-WmiObject -Class Win32_ComputerSystem
	$ComputerSystemProduct = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystemProduct"
	foreach ($obj in $ComputerSystemProduct) {
	    if ($obj.Version) {
	        $sCSPVersion = $obj.Version.Trim()
	    }
	}
	
	$sMake = $systemInfo.Manufacturer
	$sModel = $systemInfo.Model
	
    switch ($sMake) {
        "Dell Computer Corporation" { $makeAlias = "Dell" }
        "Dell Inc." { $makeAlias = "Dell" }
        "Dell Computer Corp." { $makeAlias = "Dell" }
        "IBM" { $makeAlias = "Lenovo" }
        "LENOVO" { $makeAlias = "Lenovo" }
        "Hewlett-Packard" { $makeAlias = "HP" }
        "HP" { $makeAlias = "HP" }
        "SAMSUNG ELECTRONICS CO., LTD." { $makeAlias = "Samsung" }
        "Microsoft Corporation" { $makeAlias = "Microsoft" }
        "VMware, Inc." { $makeAlias = "VMware" }
        default { $makeAlias = $sMake }
    }
	Log-Message "Get-MakeModel for Manufacturer: $makeAlias"

    switch ($sMake) {
        "IBM" { 
            if ($sCSPVersion) {
                switch ($sCSPVersion) {
                    "ThinkPad T61p" { $ModelAlias = "ThinkPad T61" }
                    Default { $ModelAlias = $sCSPVersion }
                }
            }
            if (-not $ModelAlias) {
                $sModelSubString = $sModel.Substring(0, 4)
                switch ($sModelSubString) {
                    "1706" { $ModelAlias = "ThinkPad X60" }
                    Default { $ModelAlias = $sModel }
                }
            }
        }
        "LENOVO" {
            if ($sCSPVersion) {
                switch ($sCSPVersion) {
                    "ThinkPad T61p" { $ModelAlias = "ThinkPad T61" }
                    Default { $ModelAlias = $sCSPVersion }
                }
            }
            if (-not $ModelAlias) {
                $sModelSubString = $sModel.Substring(0, 4)
                switch ($sModelSubString) {
                    "1706" { $ModelAlias = "ThinkPad X60" }
                    Default { $ModelAlias = $sModel }
                }
            }
        }
        Default {
            if ($sModel -match "\(") {
                $ModelAlias = $sModel.Substring(0, $sModel.IndexOf("(")).Trim()
            } else {
                $ModelAlias = $sModel
            }
        }
    }
	Log-Message "Get-MakeModel for Model: $ModelAlias"
    return @{ Make = $makeAlias; Model = $ModelAlias }
}

#Get Make and Model
Log-Message "Get Make and Model."
$MakeModel = Get-MakeModel
Log-Message "Make:$($MakeModel.Make) Model:$($MakeModel.Model)"

$driverDestination = "$OSDriveLetter\Drivers"
$driverSource = "$DeployShare\Drivers\$OS\$($MakeModel.Make)\$($MakeModel.Model)"
$driverSourcezip = "$DeployShare\Drivers\$OS\$($MakeModel.Make)\$($MakeModel.Model).zip"
$basedriver = "$DeployShare\Drivers\$OS\basedriver.zip"  # Base driver fallback path
$destination = "$OSDriveLetter\Drivers\Custom\"

# Create destination \Drivers directory and mark as hidden, if it doesn't already exist
try {
    if (-not (Test-Path $driverDestination)) {
        Log-Message "Creating hidden driver destination directory: ""$driverDestination""."
        $newDirectory = New-Item $driverDestination -ItemType Directory -ErrorAction Stop
        $newDirectory.Attributes += 'Hidden'
    }
} catch {
    Log-Message "Failed to create or set attributes for the destination directory: $($_.Exception.Message)"
    Exit
}

# Extract or copy driver content from specific driver sources or fallback to basedriver
try {
    if (Test-Path $driverSourcezip) {
        Log-Message "Extracting drivers from ""$driverSourcezip"" to ""$destination""."
        Expand-Archive -LiteralPath "$driverSourcezip" -DestinationPath "$destination" -ErrorAction Stop
        Log-Message "Drivers extracted successfully."
    } elseif (Test-Path $driverSource) {
        Log-Message "Copying drivers from ""$driverSource"" to ""$destination""."
        Copy-Item -Path $driverSource -Destination $destination -Recurse -ErrorAction Stop
        Log-Message "Drivers copied successfully."
    } elseif (Test-Path $basedriver) {
        Log-Message "Specific drivers not found. Extracting base driver package from ""$basedriver"" to ""$destination""."
        Expand-Archive -LiteralPath "$basedriver" -DestinationPath "$destination" -ErrorAction Stop
        Log-Message "Base drivers extracted successfully."
    } else {
        Log-Message "No specific or base drivers found at ""$driverSource"", ""$driverSourcezip"", or ""$basedriver""."
    }
} catch {
    Write-Error "An error occurred during the driver extraction or copy: $($_.Exception.Message)"
    Exit
}

Write-Output "Script complete. Exiting."

Exit
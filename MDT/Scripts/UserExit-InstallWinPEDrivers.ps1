# // ***************************************************************************
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Powershell Scripts
# //
# // File:      UserExit-InstallWinPEDrivers.ps1
# // 
# // Version:   2024.10.10-5
# // 
# // Version History
# // 2024.10.9-1: Initial version of PowerShell version
# // 2024.10.9-2: Bugfix for failing to run PNPUtil.exe to install drivers
# // 2024.10.9-3: Add Logging for debug 
# // 2024.10.10-4: Get make and model and install drivers for that model if exist or else install all drivers.
# // 2024.10.10-5: bugfix get make and model.
# // 
# // Purpose: Installs drivers from "Drivers\WinPE" and installs them to the running Windows PE environment. 
# // 
# // ***************************************************************************

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
$logFile = Join-Path -Path $logDirectory -ChildPath "UserExit-InstallWinPEDrivers.log"

# Function to log messages to the log file
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

function Get-MakeModel {
	Log-Message "Start function to get Manufacturer/Model."

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
	Log-Message "Function Get-MakeModel Manufacturer: $makeAlias"

    switch ($sMake) {
        "IBM" { 
            if ($sCSPVersion) {
                switch ($sCSPVersion) {
                    "ThinkPad T61p" { $MakeModel = "ThinkPad T61" }
                    Default { $MakeModel = $sCSPVersion }
                }
            }
            if (-not $MakeModel) {
                $sModelSubString = $sModel.Substring(0, 4)
                switch ($sModelSubString) {
                    "1706" { $MakeModel = "ThinkPad X60" }
                    Default { $MakeModel = $sModel }
                }
            }
        }
        "LENOVO" {
            if ($sCSPVersion) {
                switch ($sCSPVersion) {
                    "ThinkPad T61p" { $MakeModel = "ThinkPad T61" }
                    Default { $MakeModel = $sCSPVersion }
                }
            }
            if (-not $MakeModel) {
                $sModelSubString = $sModel.Substring(0, 4)
                switch ($sModelSubString) {
                    "1706" { $MakeModel = "ThinkPad X60" }
                    Default { $MakeModel = $sModel }
                }
            }
        }
        Default {
            if ($sModel -match "\(") {
                $MakeModel = $sModel.Substring(0, $sModel.IndexOf("(")).Trim()
            } else {
                $MakeModel = $sModel
            }
        }
    }
	Log-Message "Function Get-MakeModel Model: $MakeModel"
    return @{ Make = $makeAlias; Model = $MakeModel }
}

# Check if running in Windows PE environment
function Check-WindowsPE {
    return (Test-Path "X:\Windows\System32\winpeshl.ini")
}

# Function to install drivers from a specified folder
function Install-Drivers {
    param (
        [string]$folderName = "Drivers\WinPE"
    )

    if (-not (Check-WindowsPE)) {
        Log-Message "This script must be run in a Windows PE environment."
        Write-Host "This script must be run in a Windows PE environment."
        return
    }
	#Get Make and Model
	$MakeModel = Get-MakeModel
			
    Log-Message "Starting driver installation process."
    # Get all ready drives
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -and (Test-Path $_.Root) }

    foreach ($drive in $drives) {
        $folderPath = Join-Path -Path $drive.Root -ChildPath $folderName

        if (Test-Path $folderPath) {
            Log-Message "Found driver folder: $folderPath"
            $folderName1 =  "$folderPath\$($MakeModel.Make)\$($MakeModel.Model)"
			if (Test-Path $folderName1) {
			Install-DriversIn $folderName1	
			} else {
				Install-DriversIn $folderName				
			}
        } else {
            Log-Message "Driver folder not found: $folderPath"
        }
    }

    # Wait for all PNPUtil processes to exit
    do {
        $pnpUtilProcesses = Get-Process -Name "PNPUtil" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    } while ($pnpUtilProcesses)

    Log-Message "Driver installation process completed."
}

# Function to install drivers from a specific folder
function Install-DriversIn {
    param (
        [string]$myFolder
    )

    # Get all .inf files in the directory and subdirectories
    $infFiles = Get-ChildItem -Path $myFolder -Filter "*.inf" -Recurse

    foreach ($file in $infFiles) {
        Log-Message "Attempting to install driver: $($file.FullName)"

        # Check if the .inf file exists
        if (-not (Test-Path $file.FullName)) {
            Log-Message "File not found: $($file.FullName)"
            continue
        }

        # Dynamically get the PNPUtil path
        $pnpUtilPath = (Get-Command PNPUtil.exe).Source

        Log-Message "Found PNPUtil at: $pnpUtilPath"
        Log-Message "Running command: $pnpUtilPath /add-driver `"$($file.FullName)`" /install"

        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = $pnpUtilPath
        $processStartInfo.Arguments = "/add-driver `"$($file.FullName)`" /install"
        $processStartInfo.UseShellExecute = $false
        $processStartInfo.RedirectStandardOutput = $true
        $processStartInfo.RedirectStandardError = $true
        
        $process = [System.Diagnostics.Process]::Start($processStartInfo)
        $process.WaitForExit()

        if ($process.ExitCode -ne 0) {
            $errorOutput = $process.StandardError.ReadToEnd()
            Log-Message "Error installing '$($file.FullName)': $errorOutput"
            Write-Host "Error installing '$($file.FullName)': $errorOutput"
        } else {
            Log-Message "Successfully installed '$($file.FullName)'."
        }
    }
}

# Start the driver installation process

Install-Drivers
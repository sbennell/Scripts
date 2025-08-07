# // ***
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Powershell Scripts
# //
# // File:      UserExit-InstallWinPEDrivers.ps1
# // 
# // Version:   2025.08.07-11 (Fixed DISM Commands)
# // 
# // Version History
# // 2025.8.7-11: Fixed DISM commands for WinPE environment, improved error handling
# // 2025.8.5-10: Initial version of PowerShell version 2

# // 
# // Purpose: Installs drivers from "Drivers\WinPE" and installs them to the running Windows PE environment. 
# // 
# // ***

# Initialize logging - use local logging since OSDComputerName not available yet
try {
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $DeployShare = $tsenv.Value("DeployRoot")
    
    # Skip computer-specific logging since OSDComputerName isn't set yet
    # Go directly to local logging
    throw "Using local logging by design"
    
} catch {
    Write-Host "Using local logging (OSDComputerName not available yet)"
    
    # Fallback to local logging if TS variables fail
    $LogFolder = $null
    $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | 
              Where-Object { $_.Root -and (Test-Path $_.Root -ErrorAction SilentlyContinue) }
    
    foreach ($drive in $drives) {
        $logFolderPath = Join-Path -Path $drive.Root -ChildPath "MININT\SMSOSD\OSDLOGS"
        if (Test-Path $logFolderPath -ErrorAction SilentlyContinue) {
            $LogFolder = $logFolderPath
            break
        }
    }
    
    # If no standard log folder found, create one on the first available drive
    if (-not $LogFolder) {
        $firstDrive = $drives | Select-Object -First 1
        if ($firstDrive) {
            $LogFolder = Join-Path -Path $firstDrive.Root -ChildPath "MININT\SMSOSD\OSDLOGS"
        } else {
            $LogFolder = "C:\MININT\SMSOSD\OSDLOGS"
        }
    }
    
    # Ensure fallback log directory exists
    if (-not (Test-Path $LogFolder)) {
        New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
    }
    
    Write-Host "Fallback logging initialized: $LogFolder"
}

# Create timestamped log file
$LogFile = Join-Path $LogFolder "UserExit-InstallWinPEDrivers_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry -Force
}

# Function to get computer make and model
function Get-ComputerInfo {
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $make = $computerSystem.Manufacturer
        $model = $computerSystem.Model
        
        # Special handling for Lenovo - use Version property for more accurate model
        if ($make -like "*Lenovo*") {
            try {
                $productInfo = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction Stop
                if ($productInfo.Version -and $productInfo.Version -ne "ThinkPad") {
                    $model = $productInfo.Version
                    Write-Log "Using Lenovo Version property for model: $model" "INFO"
                }
            } catch {
                Write-Log "Could not retrieve Lenovo Version property, using standard model: $model" "WARN"
            }
        }
        
        Write-Log "Computer Make: $make" "INFO"
        Write-Log "Computer Model: $model" "INFO"
        
        return @{
            Make = $make
            Model = $model
        }
    } catch {
        Write-Log "Failed to retrieve computer information: $_" "ERROR"
        return @{
            Make = "Unknown"
            Model = "Unknown"
        }
    }
}

# Function to check if script is running in Windows PE
function Test-WinPEEnvironment {
    try {
        # Check for WinPE registry key
        $winPEKey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT" -ErrorAction SilentlyContinue
        
        if ($winPEKey) {
            Write-Log "Windows PE environment detected via registry" "INFO"
            return $true
        }
        
        # Alternative check: Look for typical WinPE drive letters and paths
        $winPEPaths = @("X:\Windows", "X:\MININT", "X:\SMS")
        foreach ($path in $winPEPaths) {
            if (Test-Path $path) {
                Write-Log "Windows PE environment detected via path: $path" "INFO"
                return $true
            }
        }
        
        # Check if we're running from a RAM drive (typical in WinPE)
        $systemDrive = $env:SystemDrive
        if ($systemDrive -eq "X:") {
            Write-Log "Windows PE environment detected via system drive: $systemDrive" "INFO"
            return $true
        }
        
        Write-Log "Standard Windows environment detected" "INFO"
        return $false
        
    } catch {
        Write-Log "Error checking WinPE environment: $_" "WARN"
        return $false
    }
}

# Function to find the WinPE drivers folder
function Find-WinPEDriversFolder {
    $DriversPath = $null
    
    # First try network path if DeployShare is available
    if ($DeployShare) {
        $networkPath = Join-Path $DeployShare "Drivers\WinPE"
        if (Test-Path $networkPath) {
            $DriversPath = $networkPath
            Write-Log "WinPE drivers folder found on network: $DriversPath" "INFO"
            return $DriversPath
        } else {
            Write-Log "Network path not accessible: $networkPath" "WARN"
        }
    }
    
    # Fallback: Search for drivers on USB/local drives
    Write-Log "Searching for WinPE drivers folder on local drives..." "INFO"
    
    $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | 
              Where-Object { $_.Root -and (Test-Path $_.Root -ErrorAction SilentlyContinue) }
    
    foreach ($drive in $drives) {
        $localPath = Join-Path $drive.Root "Drivers\WinPE"
        if (Test-Path $localPath) {
            $DriversPath = $localPath
            Write-Log "WinPE drivers folder found on local drive: $DriversPath" "INFO"
            return $DriversPath
        }
    }
    
    # If still not found, log error
    if (-not $DriversPath) {
        Write-Log "WinPE drivers folder not found in any location" "ERROR"
    }
    return $DriversPath
}

# Function to install drivers using appropriate method for WinPE
function Install-DriverToWinPE {
    param(
        [string]$DriverPath
    )
    
    Write-Log "Attempting to install driver: $DriverPath" "INFO"
    
    try {
        # Method 1: Try using PnPUtil (preferred for WinPE)
        Write-Log "Trying PnPUtil installation..." "INFO"
        $pnpResult = & pnputil.exe /add-driver $DriverPath /install 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed with PnPUtil: $(Split-Path $DriverPath -Leaf)" "INFO"
            return $true
        } else {
            Write-Log "PnPUtil failed with exit code $LASTEXITCODE : $pnpResult" "WARN"
        }
        
        # Method 2: Try DISM without image parameter (for running WinPE)
        Write-Log "Trying DISM online installation..." "INFO"
        $dismResult = & dism.exe /online /add-driver /driver:$DriverPath /ForceUnsigned 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed with DISM online: $(Split-Path $DriverPath -Leaf)" "INFO"
            return $true
        } else {
            Write-Log "DISM online failed with exit code $LASTEXITCODE : $dismResult" "WARN"
        }
        
        # Method 3: Try legacy driver installation using rundll32
        Write-Log "Trying legacy installation method..." "INFO"
        $legacyResult = & rundll32.exe setupapi,InstallHinfSection DefaultInstall 132 $DriverPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed with legacy method: $(Split-Path $DriverPath -Leaf)" "INFO"
            return $true
        } else {
            Write-Log "Legacy method failed with exit code $LASTEXITCODE : $legacyResult" "WARN"
        }
        
        Write-Log "All installation methods failed for: $(Split-Path $DriverPath -Leaf)" "ERROR"
        return $false
        
    } catch {
        Write-Log "Exception during driver installation: $_" "ERROR"
        return $false
    }
}

# Function to install WinPE drivers based on make and model
function Install-WinPEDrivers {
    param(
        [string]$DriversPath,
        [string]$Make,
        [string]$Model
    )
    
    Write-Log "Starting driver installation process" "INFO"
    Write-Log "Drivers path: '$DriversPath'" "INFO"
    Write-Log "Target Make: $Make" "INFO"
    Write-Log "Target Model: $Model" "INFO"
    
    # Clean up make/model strings for folder matching
    $CleanMake = $Make -replace '[^\w\s]', '' -replace '\s+', ' '
    $CleanModel = $Model -replace '[^\w\s]', '' -replace '\s+', ' '
    
    Write-Log "Clean Make: '$CleanMake'" "INFO"
    Write-Log "Clean Model: '$CleanModel'" "INFO"
    
    # Search for matching driver folders
    $possiblePaths = @()
    
    # Try exact make\model path
    $exactPath = Join-Path $DriversPath "$CleanMake\$CleanModel"
    if (Test-Path $exactPath) {
        $possiblePaths += $exactPath
        Write-Log "Found exact match path: $exactPath" "INFO"
    }
    
    # Try make folder with wildcard model matching
    $makePath = Join-Path $DriversPath $CleanMake
    if (Test-Path $makePath) {
        $modelFolders = Get-ChildItem -Path $makePath -Directory -ErrorAction SilentlyContinue | 
                       Where-Object { $_.Name -like "*$CleanModel*" -or $CleanModel -like "*$($_.Name)*" }
        
        foreach ($folder in $modelFolders) {
            if ($folder.FullName -notin $possiblePaths) {
                $possiblePaths += $folder.FullName
                Write-Log "Found similar model match: $($folder.FullName)" "INFO"
            }
        }
    }
    
    # Try generic/common driver folders
    $genericPaths = @("All", "Generic", "Common", "Universal")
    foreach ($generic in $genericPaths) {
        $genericPath = Join-Path $DriversPath $generic
        if (Test-Path $genericPath) {
            $possiblePaths += $genericPath
            Write-Log "Found generic driver path: $genericPath" "INFO"
        }
    }
    
    if ($possiblePaths.Count -eq 0) {
        Write-Log "No matching driver folders found for $Make $Model" "WARN"
        return $false
    }
    
    # Install drivers from found paths
    $successCount = 0
    $totalDrivers = 0
    
    foreach ($driverPath in $possiblePaths) {
        Write-Log "Processing driver path: $driverPath" "INFO"
        
        # Get all .inf files recursively
        $infFiles = Get-ChildItem -Path $driverPath -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue
        
        if ($infFiles.Count -eq 0) {
            Write-Log "No .inf files found in: $driverPath" "WARN"
            continue
        }
        
        Write-Log "Found $($infFiles.Count) driver files in: $driverPath" "INFO"
        
        foreach ($infFile in $infFiles) {
            $totalDrivers++
            
            # Install the driver using multiple methods
            $installSuccess = Install-DriverToWinPE -DriverPath $infFile.FullName
            
            if ($installSuccess) {
                $successCount++
            }
            
            # Small delay between driver installations
            Start-Sleep -Milliseconds 500
        }
    }
    
    Write-Log "Driver installation completed. Success: $successCount/$totalDrivers" "INFO"
    
    if ($successCount -gt 0) {
        return $true
    } else {
        Write-Log "No drivers were successfully installed" "ERROR"
        return $false
    }
}

# Function to validate driver installation
function Test-DriverInstallation {
    Write-Log "Performing post-installation validation..." "INFO"
    
    try {
        # Check loaded drivers using PnPUtil
        Write-Log "Checking installed drivers with PnPUtil..." "INFO"
        $pnpDrivers = & pnputil.exe /enum-drivers 2>$null
        if ($pnpDrivers -and $LASTEXITCODE -eq 0) {
            $driverCount = ($pnpDrivers | Where-Object { $_ -like "*Published Name*" }).Count
            Write-Log "PnPUtil shows $driverCount published drivers" "INFO"
        }
        
        # Check for critical hardware detection
        Write-Log "Checking hardware detection..." "INFO"
        
        # Network adapters - check multiple ways
        $networkAdapters = @()
        
        # Method 1: Connected adapters
        $connectedAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "NetConnectionStatus=2" -ErrorAction SilentlyContinue
        if ($connectedAdapters) { $networkAdapters += $connectedAdapters }
        
        # Method 2: Ethernet adapters (even if not connected)
        $ethernetAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "AdapterTypeID=0" -ErrorAction SilentlyContinue
        if ($ethernetAdapters) { 
            foreach ($adapter in $ethernetAdapters) {
                if ($adapter -notin $networkAdapters) { $networkAdapters += $adapter }
            }
        }
        
        # Method 3: All physical network adapters
        $physicalAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "PhysicalAdapter=True AND NOT Name LIKE '%Loopback%' AND NOT Name LIKE '%Teredo%'" -ErrorAction SilentlyContinue
        if ($physicalAdapters) {
            foreach ($adapter in $physicalAdapters) {
                if ($adapter -notin $networkAdapters) { $networkAdapters += $adapter }
            }
        }
        
        if ($networkAdapters.Count -gt 0) {
            Write-Log "Network adapters found: $($networkAdapters.Count)" "INFO"
            foreach ($adapter in $networkAdapters) {
                $status = switch ($adapter.NetConnectionStatus) {
                    2 { "Connected" }
                    7 { "Media Disconnected" }
                    0 { "Disconnected" }
                    default { "Status: $($adapter.NetConnectionStatus)" }
                }
                Write-Log "  - $($adapter.Name) [$status]" "INFO"
            }
        } else {
            Write-Log "No network adapters detected (normal for USB-based WinPE deployment)" "INFO"
        }
        
        # Storage controllers
        $storageControllers = Get-CimInstance -ClassName Win32_SCSIController -ErrorAction SilentlyContinue
        if ($storageControllers) {
            Write-Log "Storage controllers detected: $($storageControllers.Count)" "INFO"
            foreach ($controller in $storageControllers) {
                Write-Log "  - $($controller.Name)" "INFO"
            }
        }
        
        # Disk drives
        $diskDrives = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction SilentlyContinue
        if ($diskDrives) {
            Write-Log "Disk drives detected: $($diskDrives.Count)" "INFO"
            foreach ($disk in $diskDrives) {
                $sizeGB = [math]::Round($disk.Size / 1GB, 2)
                Write-Log "  - $($disk.Model) ($sizeGB GB)" "INFO"
            }
        }
        
        return $true
        
    } catch {
        Write-Log "Error during post-installation validation: $_" "WARN"
        return $false
    }
}

# Start logging
Write-Log "=== WinPE Driver Installation Started ===" "INFO"
Write-Log "Script Version: 2025.08.07-11 (Fixed DISM Commands)" "INFO"

# Check if running in Windows PE
$IsWinPE = Test-WinPEEnvironment

# Get computer information
$ComputerInfo = Get-ComputerInfo

# Find WinPE drivers folder
$WinPEDriversPath = Find-WinPEDriversFolder

if (-not $WinPEDriversPath) {
    Write-Log "Cannot continue without WinPE drivers folder" "ERROR"
    exit 1
}

# Main script execution
Write-Log "=== Main Script Execution Started ===" "INFO"

# Validate WinPE environment
if (-not $IsWinPE) {
    Write-Log "Script is not running in Windows PE environment. Exiting." "ERROR"
    Write-Log "=== Script execution completed with errors ===" "ERROR"
    exit 1
}

# Validate drivers path
if (-not $WinPEDriversPath) {
    Write-Log "WinPE drivers path not found. Cannot continue." "ERROR"
    Write-Log "=== Script execution completed with errors ===" "ERROR"
    exit 1
}

# Validate computer information
if ($ComputerInfo.Make -eq "Unknown" -or $ComputerInfo.Model -eq "Unknown") {
    Write-Log "Could not determine computer make/model. Attempting generic driver installation." "WARN"
    
    # Try installing from generic folders only
    $installResult = Install-WinPEDrivers -DriversPath $WinPEDriversPath -Make "Generic" -Model "All"
    
    if ($installResult) {
        Write-Log "Generic driver installation completed" "INFO"
    } else {
        Write-Log "Generic driver installation failed" "ERROR"
        Write-Log "=== Script execution completed with errors ===" "ERROR"
        exit 1
    }
} else {
    # Normal execution with known make/model
    Write-Log "Proceeding with driver installation for $($ComputerInfo.Make) $($ComputerInfo.Model)" "INFO"
    
    # Install WinPE drivers based on computer make and model
    $installResult = Install-WinPEDrivers -DriversPath $WinPEDriversPath -Make $ComputerInfo.Make -Model $ComputerInfo.Model
    
    if ($installResult) {
        Write-Log "WinPE driver installation completed successfully" "INFO"
    } else {
        Write-Log "Driver installation failed but continuing with validation..." "WARN"
    }
}

# Post-installation validation
$validationResult = Test-DriverInstallation

Write-Log "=== WinPE Driver Installation Script Completed ===" "INFO"
Write-Log "Log file saved to: $LogFile" "INFO"

# Log TS environment status (if available)
if ($tsenv -and $DeployShare) {
    Write-Log "Task Sequence Environment loaded successfully" "INFO"
    Write-Log "DeployShare: $DeployShare" "INFO"
} else {
    Write-Log "Task Sequence Environment not available - using fallback logging" "INFO"
}

# Return appropriate exit code
if ($installResult -or $validationResult) {
    Write-Log "Script completed successfully" "INFO"
    exit 0
} else {
    Write-Log "Script completed with issues - check logs for details" "WARN"
    exit 1
}
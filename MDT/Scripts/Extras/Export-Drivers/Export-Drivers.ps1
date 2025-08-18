# // ***
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Powershell Scripts
# //
# // File:      Export-Drivers.ps1
# // 
# // Version:   2025.08.13-5
# // 
# // Version History
# // 2025.08.13-5: Modified to get computer name from Windows instead of OSDComputerName task sequence variable
# // 2025.08.13-4: Complete rewrite to match UserExit-InstallWinPEDrivers.ps1 and Copy-Drivers.ps1 structure
# // 2024.10.4-3: Previous version with basic functionality
# // 2024.10.4-2: Improved error handling, fixed variable names, and added zip functionality
# // 2024.10.4-1: Get Make and Model from MDT
# // 2024.3.14-2: Initial version

# // 
# // Purpose: Export drivers from current system and organize them in DeployShare\Drivers folder structure
# // 
# // ***

# Function to get computer name from Windows
function Get-WindowsComputerName {
    try {
        # Try multiple methods to get computer name
        $computerName = $env:COMPUTERNAME
        
        if (-not $computerName -or $computerName.Trim() -eq "") {
            # Fallback method using .NET
            $computerName = [System.Environment]::MachineName
        }
        
        if (-not $computerName -or $computerName.Trim() -eq "") {
            # Second fallback using WMI
            $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
            if ($computerSystem) {
                $computerName = $computerSystem.Name
            }
        }
        
        if (-not $computerName -or $computerName.Trim() -eq "") {
            # Final fallback - use a default name with timestamp
            $computerName = "UNKNOWN-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Write-Warning "Could not determine computer name, using fallback: $computerName"
        }
        
        return $computerName.Trim().ToUpper()
        
    } catch {
        Write-Warning "Error getting computer name: $_"
        return "UNKNOWN-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }
}

# Initialize Task Sequence Environment
try {
    Write-Host "Initializing task sequence environment..."
    
    # Create task sequence environment object
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    
    # Get required variables from task sequence
    $DeployShare = $TSEnv.Value("DeployRoot")
    
    # Get computer name from Windows instead of task sequence
    $OSDComputerName = Get-WindowsComputerName
    Write-Host "Computer name from Windows: $OSDComputerName"
    
    # Validate that DeployShare is available
    if (-not $DeployShare -or $DeployShare.Trim() -eq "") {
        throw "DeployRoot not available from task sequence or is empty"
    }
    
    # Validate that DeployShare path exists and is accessible
    if (-not (Test-Path $DeployShare -PathType Container)) {
        throw "DeployRoot path '$DeployShare' is not accessible or does not exist"
    }
    
    # Create computer-specific log folder
    $LogFolder = "$DeployShare\Logs\$OSDComputerName"
    
    Write-Host "Target log folder: $LogFolder"
    
    # Ensure log directory exists with error handling
    try {
        if (-not (Test-Path $LogFolder)) {
            Write-Host "Creating log directory..."
            New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
        }
        
        # Test write permissions to the log folder
        $TestFile = "$LogFolder\test_write_$(Get-Date -Format 'yyyyMMdd_HHmmss').tmp"
        "Test" | Out-File -FilePath $TestFile -Force
        Remove-Item -Path $TestFile -Force
        
    } catch {
        throw "Failed to create or write to log directory '$LogFolder': $_"
    }
    
    # Set additional useful variables
    $LogTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ScriptName = $MyInvocation.MyCommand.Name
    
    # Output success information
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Task Sequence Initialization Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Computer Name: $OSDComputerName" -ForegroundColor Cyan
    Write-Host "Deploy Share: $DeployShare" -ForegroundColor Cyan
    Write-Host "Log Folder: $LogFolder" -ForegroundColor Cyan
    Write-Host "Initialized: $LogTimestamp" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
    
    # Export variables for use by other scripts (optional)
    $Global:TSLogFolder = $LogFolder
    $Global:TSDeployShare = $DeployShare
    $Global:TSComputerName = $OSDComputerName

    
} catch {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "TASK SEQUENCE INITIALIZATION FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Red
    Write-Host "Script: $($MyInvocation.MyCommand.Name)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Start-Sleep 30
    exit 1
}

# Create timestamped log file
$LogFile = Join-Path $LogFolder "Export-Drivers.ps1_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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

# Function to get OS information
function Get-OSInfo {
    try {
        $OSVersion = [System.Environment]::OSVersion.Version
        $OSName = "Windows Unknown"
        
        # Determine OS Name based on OS Version
        if ($OSVersion -ge [System.Version]"10.0.22000.0") {
            $OSName = "Windows 11"
        } elseif ($OSVersion -ge [System.Version]"10.0.0.0") {
            $OSName = "Windows 10"
        } elseif ($OSVersion -ge [System.Version]"6.3.0.0") {
            $OSName = "Windows 8.1"
        } elseif ($OSVersion -ge [System.Version]"6.2.0.0") {
            $OSName = "Windows 8"
        } elseif ($OSVersion -ge [System.Version]"6.1.0.0") {
            $OSName = "Windows 7"
        }
        
        Write-Log "Operating System: $OSName (Version: $OSVersion)" "INFO"
        
        return @{
            Name = $OSName
            Version = $OSVersion
        }
        
    } catch {
        Write-Log "Failed to retrieve OS information: $_" "ERROR"
        return @{
            Name = "Windows Unknown"
            Version = $null
        }
    }
}

# Function to sanitize folder names
function ConvertTo-SanitizedFolderName {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FolderName
    )
    
    # Remove invalid characters and trim spaces/dots
    ($FolderName -replace '[<>:"/\\|?*]', '_').TrimStart(" ").TrimEnd(". ")
}

# Function to find deployment share using media.tag (USB detection)
function Find-USBDeploymentShare {
    Write-Log "Searching for USB deployment share using media.tag..." "INFO"
    
    # Search all drives for media.tag to identify USB deployment drive
    $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | 
              Where-Object { $_.Root -and (Test-Path $_.Root -ErrorAction SilentlyContinue) }
    
    foreach ($drive in $drives) {
        # Look for media.tag in Deploy\Scripts folder only
        $mediaTagPath = Join-Path $drive.Root "Deploy\Scripts\media.tag"
        
        if (Test-Path $mediaTagPath) {
            $deployRoot = Join-Path $drive.Root "Deploy"
            Write-Log "Found media.tag on drive $($drive.Name): $mediaTagPath" "INFO"
            Write-Log "Using USB deployment share: $deployRoot" "INFO"
            return $deployRoot
        }
    }
    
    Write-Log "No media.tag found in Deploy\Scripts on any drive - not running from USB" "INFO"
    return $null
}

# Function to determine driver destination path
function Get-DriverDestinationPath {
    param(
        [string]$Make,
        [string]$Model,
        [string]$OSName
    )
    
    # First check if running from USB media
    $USBDeployShare = Find-USBDeploymentShare
    
    if ($USBDeployShare) {
        # Use USB deployment share
        $driverDestination = Join-Path $USBDeployShare "Drivers"
        Write-Log "Using USB deployment share drivers path: $driverDestination" "INFO"
    } else {
        # Use network DeployShare from task sequence
        $driverDestination = Join-Path $DeployShare "Drivers"
        Write-Log "Using network DeployShare drivers path: $driverDestination" "INFO"
    }
    
    # Build full path: \Drivers\OS\MAKE\MODEL\
    $fullPath = Join-Path $driverDestination $OSName
    $fullPath = Join-Path $fullPath $Make.ToUpper()
    $fullPath = Join-Path $fullPath $Model
    
    Write-Log "Driver destination path: $fullPath" "INFO"
    
    return $fullPath
}

# Function to prepare driver destination folder
function Initialize-DriverDestination {
    param(
        [string]$DestinationPath
    )
    
    Write-Log "Initializing driver destination: $DestinationPath" "INFO"
    
    try {
        # Remove existing folder if it exists
        if (Test-Path $DestinationPath) {
            Write-Log "Removing existing driver folder..." "INFO"
            Remove-Item $DestinationPath -Recurse -Force -ErrorAction Stop
        }
        
        # Create new folder structure
        New-Item -ItemType Directory -Path $DestinationPath -Force -ErrorAction Stop | Out-Null
        Write-Log "Driver destination folder created successfully" "INFO"
        return $true
        
    } catch {
        Write-Log "Failed to initialize driver destination: $_" "ERROR"
        return $false
    }
}

# Function to export drivers using DISM
function Export-SystemDrivers {
    param(
        [string]$DestinationPath
    )
    
    Write-Log "Starting driver export to: $DestinationPath" "INFO"
    
    try {
        # Use Export-WindowsDriver for online system
        Write-Log "Exporting Windows drivers using Export-WindowsDriver cmdlet..." "INFO"
        $ExportedDrivers = Export-WindowsDriver -Online -Destination $DestinationPath -ErrorAction Stop
        
        Write-Log "Successfully exported $($ExportedDrivers.Count) drivers" "INFO"
        return $ExportedDrivers
        
    } catch {
        Write-Log "Driver export failed: $_" "ERROR"
        
        # Fallback: Try DISM command directly
        try {
            Write-Log "Attempting fallback export using DISM..." "WARN"
            $dismResult = & dism.exe /online /export-driver /destination:$DestinationPath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "DISM export completed successfully" "INFO"
                
                # Get list of exported drivers for organization
                $infFiles = Get-ChildItem -Path $DestinationPath -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue
                Write-Log "Found $($infFiles.Count) exported driver files" "INFO"
                
                # Create mock driver objects for organization function
                $mockDrivers = @()
                foreach ($inf in $infFiles) {
                    $mockDrivers += [PSCustomObject]@{
                        OriginalFileName = $inf.FullName
                        ClassName = "Unknown"
                        ProviderName = "Unknown"
                    }
                }
                
                return $mockDrivers
                
            } else {
                Write-Log "DISM export failed with exit code: $LASTEXITCODE" "ERROR"
                Write-Log "DISM output: $dismResult" "ERROR"
                return $null
            }
            
        } catch {
            Write-Log "DISM fallback also failed: $_" "ERROR"
            return $null
        }
    }
}

# Function to organize exported drivers
function Optimize-DriverOrganization {
    param(
        [array]$ExportedDrivers,
        [string]$DriverPath
    )
    
    Write-Log "Starting driver organization..." "INFO"
    Write-Log "Processing $($ExportedDrivers.Count) exported drivers" "INFO"
    
    $organizedCount = 0
    $deletedCount = 0
    $errorCount = 0
    
    foreach ($Driver in $ExportedDrivers) {
        try {
            # Get parent folder name from original file path
            $OriginalPath = $Driver.OriginalFileName
            $ParentFolder = Split-Path -Path (Split-Path -Path $OriginalPath -Parent) -Leaf
            
            # Skip if we can't determine the parent folder
            if (-not $ParentFolder) {
                Write-Log "Could not determine parent folder for: $OriginalPath" "WARN"
                $errorCount++
                continue
            }
            
            # Check if this is a printer driver and delete it
            if ($Driver.ClassName -eq "Printer") {
                try {
                    $printerPath = Join-Path $DriverPath $ParentFolder
                    if (Test-Path $printerPath) {
                        Remove-Item $printerPath -Recurse -Force -ErrorAction Stop
                        Write-Log "Deleted printer driver: $ParentFolder" "INFO"
                        $deletedCount++
                    }
                } catch {
                    Write-Log "Failed to remove printer driver folder '$ParentFolder': $_" "WARN"
                    $errorCount++
                }
                continue
            }
            
            # Organize non-printer drivers
            $ClassName = if ($Driver.ClassName -and $Driver.ClassName -ne "Unknown") { 
                ConvertTo-SanitizedFolderName $Driver.ClassName 
            } else { 
                "Unknown" 
            }
            
            $ProviderName = if ($Driver.ProviderName -and $Driver.ProviderName -ne "Unknown") { 
                ConvertTo-SanitizedFolderName $Driver.ProviderName 
            } else { 
                "Unknown" 
            }
            
            $Destination = Join-Path $DriverPath $ClassName
            $Destination = Join-Path $Destination $ProviderName
            
            # Create destination directory
            try {
                New-Item -ItemType Directory -Path $Destination -Force -ErrorAction Stop | Out-Null
                
                # Move the driver folder
                $SourcePath = Join-Path $DriverPath $ParentFolder
                if (Test-Path $SourcePath) {
                    Move-Item $SourcePath $Destination -ErrorAction Stop
                    Write-Log "Organized driver: $ParentFolder -> $ClassName\$ProviderName" "INFO"
                    $organizedCount++
                } else {
                    Write-Log "Source driver folder not found: $SourcePath" "WARN"
                    $errorCount++
                }
                
            } catch {
                Write-Log "Failed to organize driver '$ParentFolder': $_" "WARN"
                Write-Log "  Source: $SourcePath" "WARN"
                Write-Log "  Destination: $Destination" "WARN"
                $errorCount++
            }
            
        } catch {
            Write-Log "Error processing driver: $_" "ERROR"
            $errorCount++
        }
    }
    
    Write-Log "Driver organization completed:" "INFO"
    Write-Log "  Organized: $organizedCount" "INFO"
    Write-Log "  Deleted (printers): $deletedCount" "INFO"
    Write-Log "  Errors: $errorCount" "INFO"
    
    return ($organizedCount + $deletedCount) -gt 0
}

# Function to create optional ZIP archive
function Create-DriverArchive {
    param(
        [string]$DriverPath,
        [string]$Make,
        [string]$Model,
        [string]$OSName
    )
    
    # Build ZIP file path
    $ParentPath = Split-Path $DriverPath -Parent
    $ZipFileName = "$Model.zip"
    $ZipPath = Join-Path $ParentPath $ZipFileName
    
    Write-Log "Creating driver archive: $ZipPath" "INFO"
    
    try {
        # Remove existing ZIP if present
        if (Test-Path $ZipPath) {
            Write-Log "Removing existing ZIP file: $ZipPath" "INFO"
            Remove-Item $ZipPath -Force -ErrorAction Stop
        }
        
        # Create new ZIP archive
        Write-Log "Compressing drivers to ZIP archive..." "INFO"
        Compress-Archive -Path "$DriverPath\*" -DestinationPath $ZipPath -ErrorAction Stop
        
        # Verify ZIP was created
        if (Test-Path $ZipPath) {
            $ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
            Write-Log "Driver archive created successfully: $ZipPath ($ZipSize MB)" "INFO"
            return $true
        } else {
            Write-Log "ZIP archive was not created" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Failed to create driver archive: $_" "ERROR"
        return $false
    }
}

# Function to validate exported drivers
function Test-ExportedDrivers {
    param(
        [string]$DriverPath
    )
    
    Write-Log "Validating exported drivers..." "INFO"
    
    try {
        # Count total files
        $AllFiles = Get-ChildItem -Path $DriverPath -Recurse -File -ErrorAction SilentlyContinue
        $InfFiles = Get-ChildItem -Path $DriverPath -Recurse -Filter "*.inf" -ErrorAction SilentlyContinue
        $SysFiles = Get-ChildItem -Path $DriverPath -Recurse -Filter "*.sys" -ErrorAction SilentlyContinue
        
        Write-Log "Export validation results:" "INFO"
        Write-Log "  Total files: $($AllFiles.Count)" "INFO"
        Write-Log "  INF files: $($InfFiles.Count)" "INFO"
        Write-Log "  SYS files: $($SysFiles.Count)" "INFO"
        
        # Check folder structure
        $SubFolders = Get-ChildItem -Path $DriverPath -Directory -ErrorAction SilentlyContinue
        Write-Log "  Organized categories: $($SubFolders.Count)" "INFO"
        
        foreach ($folder in $SubFolders) {
            $ProviderFolders = Get-ChildItem -Path $folder.FullName -Directory -ErrorAction SilentlyContinue
            Write-Log "    $($folder.Name): $($ProviderFolders.Count) providers" "INFO"
        }
        
        # Minimum validation - should have at least some INF files
        if ($InfFiles.Count -gt 0) {
            Write-Log "Driver export validation passed" "INFO"
            return $true
        } else {
            Write-Log "Driver export validation failed - no INF files found" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Error during driver validation: $_" "ERROR"
        return $false
    }
}

# Main execution logic
Write-Log "=== Export-Drivers.ps1 Script Started ===" "INFO"
Write-Log "Script Version: 2025.08.13-5 (Updated to get computer name from Windows)" "INFO"

# Get computer information
$computerInfo = Get-ComputerInfo
if ($computerInfo.Make -eq "Unknown" -or $computerInfo.Model -eq "Unknown") {
    Write-Log "Could not determine computer make/model. This may affect driver organization." "WARN"
}

# Get OS information
$osInfo = Get-OSInfo

# Check for unsupported OS versions
if ($osInfo.Name -eq "Windows 7") {
    Write-Log "Windows 7 is not supported by this script version" "ERROR"
    Write-Log "=== Export-Drivers.ps1 Script Failed ===" "ERROR"
    exit 1
}

# Determine driver destination path
$driverPath = Get-DriverDestinationPath -Make $computerInfo.Make -Model $computerInfo.Model -OSName $osInfo.Name

# Initialize driver destination
$initSuccess = Initialize-DriverDestination -DestinationPath $driverPath
if (-not $initSuccess) {
    Write-Log "Failed to initialize driver destination" "ERROR"
    Write-Log "=== Export-Drivers.ps1 Script Failed ===" "ERROR"
    exit 1
}

# Export system drivers
$exportedDrivers = Export-SystemDrivers -DestinationPath $driverPath
if (-not $exportedDrivers -or $exportedDrivers.Count -eq 0) {
    Write-Log "No drivers were exported" "ERROR"
    Write-Log "=== Export-Drivers.ps1 Script Failed ===" "ERROR"
    exit 1
}

# Organize exported drivers
$organizeSuccess = Optimize-DriverOrganization -ExportedDrivers $exportedDrivers -DriverPath $driverPath
if (-not $organizeSuccess) {
    Write-Log "Driver organization encountered issues but continuing..." "WARN"
}

# Optional: Create ZIP archive (uncomment to enable)
# $archiveSuccess = Create-DriverArchive -DriverPath $driverPath -Make $computerInfo.Make -Model $computerInfo.Model -OSName $osInfo.Name

# Validate exported drivers
$validationSuccess = Test-ExportedDrivers -DriverPath $driverPath

# Final results
if ($validationSuccess) {
    Write-Log "=== Export-Drivers.ps1 Script Completed Successfully ===" "INFO"
    Write-Log "Drivers exported to: $driverPath" "INFO"
    Write-Log "Log file saved to: $LogFile" "INFO"
    exit 0
} else {
    Write-Log "=== Export-Drivers.ps1 Script Completed with Issues ===" "WARN"
    Write-Log "Check log file for details: $LogFile" "WARN"
    exit 1
}
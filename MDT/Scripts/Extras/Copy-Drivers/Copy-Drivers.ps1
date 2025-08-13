# // ***
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Powershell Scripts
# //
# // File:      Copy-Drivers.ps1
# // 
# // Version:   2025.08.07-11 (Fixed DISM Commands)
# // 
# // Version History
# // 2025.8.7-10: Initial version of PowerShell version 2

# // 
# // Purpose: Installs drivers from "Drivers\" and copies appropriate drivers to the OS drive during Windows PE deployment. 
# // 
# // ***

# Initialize Task Sequence Environment
try {
    Write-Host "Initializing task sequence environment..."
    
    # Create task sequence environment object
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    
    # Get required variables from task sequence
    $DeployShare = $TSEnv.Value("DeployRoot")
    $OSDComputerName = $TSEnv.Value("OSDComputerName")
    $OSDriveLetter = $TSEnv.Value("OSDisk")
    
    # Validate that DeployShare is available
    if (-not $DeployShare -or $DeployShare.Trim() -eq "") {
        throw "DeployRoot not available from task sequence or is empty"
    }
    
    # Validate that OSDComputerName is available
    if (-not $OSDComputerName -or $OSDComputerName.Trim() -eq "") {
        throw "OSDComputerName not available from task sequence or is empty"
    }

    # Validate that OSDisk is available
    if (-not $OSDisk -or $OSDisk.Trim() -eq "") {
        throw "OSDisk not available from task sequence or is empty"
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
    Write-Host "OS Drive Letter: $OSDriveLetter" -ForegroundColor Cyan
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
    
    exit 1
}
# Create timestamped log file
$LogFile = Join-Path $LogFolder "Copy-Drivers.ps1_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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

# Function to find drivers and get model-specific path
function Get-DriverPath {
    param(
        [string]$Make,
        [string]$Model,
        [string]$OS
    )
    
    Write-Log "Searching for drivers for: $Make $Model on $OS" "INFO"
    
    # Step 1: Find base drivers folder
    $BasePath = $null
    
    # First try network path if DeployShare is available
    if ($DeployShare) {
        $networkPath = Join-Path $DeployShare "Drivers\"
        if (Test-Path $networkPath) {
            $BasePath = $networkPath
            Write-Log "Base drivers folder found on network: $BasePath" "INFO"
        } else {
            Write-Log "Network path not accessible: $networkPath" "WARN"
        }
    }
    
    # Fallback: Search for drivers on USB/local drives if network failed
    if (-not $BasePath) {
        Write-Log "Searching for drivers folder on local drives..." "INFO"
        
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | 
                  Where-Object { $_.Root -and (Test-Path $_.Root -ErrorAction SilentlyContinue) }
        
        foreach ($drive in $drives) {
            $localPath = Join-Path $drive.Root "Drivers\"
            if (Test-Path $localPath) {
                $BasePath = $localPath
                Write-Log "Base drivers folder found on local drive: $BasePath" "INFO"
                break
            }
        }
    }
    
    # If no base path found, return failure
    if (-not $BasePath) {
        Write-Log "Base drivers folder not found in any location" "ERROR"
        return @{
            BasePath = $null
            ModelPath = $null
            Type = $null
            Found = $false
            Error = "Base drivers folder not found"
        }
    }
    
    # Check if model is missing or empty
    if (-not $Model -or $Model.Trim() -eq "") {
        Write-Log "Model information is missing or empty. Skipping model-specific search and using generic drivers." "WARN"
        
        # Jump directly to generic driver search
        Write-Log "Searching for generic drivers due to missing model..." "WARN"
        
        # Try OS-specific Generic folder first
        $genericPath = Join-Path $BasePath "$OS\Generic\"
        Write-Log "Checking for OS-specific generic driver folder: $genericPath" "INFO"
        
        if (Test-Path $genericPath -PathType Container) {
            Write-Log "Found OS-specific generic driver folder: $genericPath" "INFO"
            return @{
                BasePath = $BasePath
                ModelPath = $genericPath
                Type = "Folder"
                Found = $true
                Error = "Using OS-specific generic drivers (model information missing)"
            }
        }
        
        # Try OS-specific GenericDrivers.zip
        $osGenericZipPath = Join-Path $BasePath "$OS\GenericDrivers.zip"
        Write-Log "Checking for OS-specific generic driver ZIP: $osGenericZipPath" "INFO"
        
        if (Test-Path $osGenericZipPath -PathType Leaf) {
            Write-Log "Found OS-specific generic driver ZIP: $osGenericZipPath" "INFO"
            return @{
                BasePath = $BasePath
                ModelPath = $osGenericZipPath
                Type = "ZIP"
                Found = $true
                Error = "Using OS-specific generic drivers (model information missing)"
            }
        }
        
        # No generic drivers found either
        Write-Log "No generic drivers found (model information missing)" "ERROR"
        return @{
            BasePath = $BasePath
            ModelPath = $null
            Type = $null
            Found = $false
            Error = "No generic drivers found (model information missing)"
        }
    }
    
    # Step 2: Build model-specific path (only if model is available)
    Write-Log "Building model-specific driver path..." "INFO"
    
    # Build the expected path: \Drivers\OS\MAKE\MODEL\
    $modelPath = Join-Path $BasePath $OS
    $modelPath = Join-Path $modelPath $Make.ToUpper()
    $modelPath = Join-Path $modelPath $Model
    
    Write-Log "Checking for driver path: $modelPath" "INFO"
    
    # First check if the folder exists
    if (Test-Path $modelPath -PathType Container) {
        Write-Log "Found model-specific driver folder: $modelPath" "INFO"
        return @{
            BasePath = $BasePath
            ModelPath = $modelPath
            Type = "Folder"
            Found = $true
            Error = $null
        }
    }
    
    # If folder doesn't exist, check for ZIP file
    $zipPath = "$modelPath.zip"
    Write-Log "Checking for driver ZIP: $zipPath" "INFO"
    
    if (Test-Path $zipPath -PathType Leaf) {
        Write-Log "Found model-specific driver ZIP: $zipPath" "INFO"
        return @{
            BasePath = $BasePath
            ModelPath = $zipPath
            Type = "ZIP"
            Found = $true
            Error = $null
        }
    }
    
    # Step 3: Try partial matches if exact match failed
    Write-Log "Exact match not found. Searching for similar model names..." "WARN"
    
    $makeFolder = Join-Path $BasePath $OS | Join-Path -ChildPath $Make.ToUpper()
    if (Test-Path $makeFolder -PathType Container) {
        $availableFolders = Get-ChildItem -Path $makeFolder -Directory | Select-Object -ExpandProperty Name
        $availableZips = Get-ChildItem -Path $makeFolder -Filter "*.zip" | Select-Object -ExpandProperty BaseName
        
        Write-Log "Available folders in $Make directory: $($availableFolders -join ', ')" "INFO"
        Write-Log "Available ZIPs in $Make directory: $($availableZips -join ', ')" "INFO"
        
        # Try to find a partial match in folders first
        $partialMatch = $availableFolders | Where-Object { $_ -like "*$($Model.Split(' ')[0])*" } | Select-Object -First 1
        if ($partialMatch) {
            $partialPath = Join-Path $makeFolder $partialMatch
            Write-Log "Found partial match folder: $partialPath" "WARN"
            return @{
                BasePath = $BasePath
                ModelPath = $partialPath
                Type = "Folder"
                Found = $true
                Error = "Partial match used"
            }
        }
        
        # Try to find a partial match in ZIP files
        $partialZipMatch = $availableZips | Where-Object { $_ -like "*$($Model.Split(' ')[0])*" } | Select-Object -First 1
        if ($partialZipMatch) {
            $partialZipPath = Join-Path $makeFolder "$partialZipMatch.zip"
            Write-Log "Found partial match ZIP: $partialZipPath" "WARN"
            return @{
                BasePath = $BasePath
                ModelPath = $partialZipPath
                Type = "ZIP"
                Found = $true
                Error = "Partial match used"
            }
        }
    }
    
    # Step 4: Try generic drivers as fallback
    Write-Log "No model-specific drivers found. Trying generic drivers..." "WARN"
    
    # Try OS-specific Generic folder first
    $genericPath = Join-Path $BasePath "$OS\Generic\"
    Write-Log "Checking for OS-specific generic driver folder: $genericPath" "INFO"
    
    if (Test-Path $genericPath -PathType Container) {
        Write-Log "Found OS-specific generic driver folder: $genericPath" "INFO"
        return @{
            BasePath = $BasePath
            ModelPath = $genericPath
            Type = "Folder"
            Found = $true
            Error = "Using OS-specific generic drivers (no model-specific drivers found)"
        }
    }
    
    # Try OS-specific GenericDrivers.zip
    $osGenericZipPath = Join-Path $BasePath "$OS\GenericDrivers.zip"
    Write-Log "Checking for OS-specific generic driver ZIP: $osGenericZipPath" "INFO"
    
    if (Test-Path $osGenericZipPath -PathType Leaf) {
        Write-Log "Found OS-specific generic driver ZIP: $osGenericZipPath" "INFO"
        return @{
            BasePath = $BasePath
            ModelPath = $osGenericZipPath
            Type = "ZIP"
            Found = $true
            Error = "Using OS-specific generic drivers (no model-specific drivers found)"
        }
    }
    
    # Step 5: No drivers found at all
    Write-Log "No drivers found for: $Make $Model (including generic fallback)" "ERROR"
    return @{
        BasePath = $BasePath
        ModelPath = $null
        Type = $null
        Found = $false
        Error = "No drivers found (model-specific or generic)"
    }
}

# Function to extract ZIP file directly to destination or copy folder
function Copy-DriversToOS {
    param(
        [string]$SourcePath,
        [string]$SourceType,
        [string]$DestinationDrive
    )
    
    # Create destination path
    $destinationPath = Join-Path $DestinationDrive "Drivers\Custom\"
    Write-Log "Preparing to copy drivers to: $destinationPath" "INFO"
    
    # Ensure destination directory exists
    try {
        if (-not (Test-Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            Write-Log "Created destination directory: $destinationPath" "INFO"
        }
    } catch {
        Write-Log "Failed to create destination directory: $_" "ERROR"
        return $false
    }
    
    # Handle ZIP file - extract directly to destination
    if ($SourceType -eq "ZIP") {
        try {
            Write-Log "Extracting ZIP file directly to destination: $SourcePath" "INFO"
            Expand-Archive -Path $SourcePath -DestinationPath $destinationPath -Force
            
            # Verify extraction was successful by checking if files were created
            $extractedItems = Get-ChildItem -Path $destinationPath -Recurse -ErrorAction SilentlyContinue
            if ($extractedItems) {
                Write-Log "Successfully extracted ZIP file to OS drive ($($extractedItems.Count) items)" "INFO"
                return $true
            } else {
                Write-Log "ZIP extraction appeared to succeed but no files found in destination" "ERROR"
                return $false
            }
            
        } catch {
            Write-Log "Error extracting ZIP file directly to destination: $_" "ERROR"
            return $false
        }
    }
    
    # Handle Folder - copy contents
    elseif ($SourceType -eq "Folder") {
        try {
            Write-Log "Copying drivers from folder: $SourcePath" "INFO"
            Write-Log "Copying drivers to: $destinationPath" "INFO"
            
            # Use robocopy for reliable copying with progress
            $robocopyArgs = @(
                $SourcePath,
                $destinationPath,
                "/E",          # Copy subdirectories including empty ones
                "/R:3",        # Retry 3 times on failed copies
                "/W:5",        # Wait 5 seconds between retries  
                "/NP",         # No progress percentage
                "/NDL",        # No directory list
                "/NFL",        # No file list
                "/XF",         # Exclude files
                "*.zip"        # Exclude ZIP files
            )
            
            Write-Log "Starting robocopy with args: $($robocopyArgs -join ' ')" "INFO"
            $robocopyResult = & robocopy @robocopyArgs
            $exitCode = $LASTEXITCODE
            
            # Robocopy exit codes: 0-7 are success, 8+ are errors
            if ($exitCode -lt 8) {
                Write-Log "Successfully copied drivers to OS drive (exit code: $exitCode)" "INFO"
                return $true
            } else {
                Write-Log "Robocopy failed with exit code: $exitCode" "ERROR"
                Write-Log "Robocopy output: $($robocopyResult -join '; ')" "ERROR"
                return $false
            }
            
        } catch {
            Write-Log "Error during driver copy operation: $_" "ERROR"
            return $false
        }
    }
    
    else {
        Write-Log "Unknown source type: $SourceType" "ERROR"
        return $false
    }
}

# Function to cleanup temporary files (no longer needed but kept for compatibility)
function Remove-TempDrivers {
    param(
        [string]$TempPath
    )
    # This function is no longer needed since we extract directly to destination
    # Kept for compatibility in case of future changes
    Write-Log "No temporary cleanup needed - drivers extracted directly to destination" "INFO"
}

# Main execution logic
Write-Log "=== Copy-Drivers.ps1 Script Started ===" "INFO"

# Get computer information
$computerInfo = Get-ComputerInfo
if ($computerInfo.Make -eq "Unknown" -or $computerInfo.Model -eq "Unknown") {
    Write-Log "Could not determine computer make/model. Script will attempt generic drivers only." "WARN"
}

# Find drivers
$driverInfo = Get-DriverPath -Make $computerInfo.Make -Model $computerInfo.Model -OS $OS

if (-not $driverInfo.Found) {
    Write-Log "No drivers found for this system. Exiting." "ERROR"
    exit 1
}

# Log driver information
Write-Log "Driver search completed successfully:" "INFO"
Write-Log "  Base Path: $($driverInfo.BasePath)" "INFO"
Write-Log "  Model Path: $($driverInfo.ModelPath)" "INFO"
Write-Log "  Type: $($driverInfo.Type)" "INFO"
if ($driverInfo.Error) {
    Write-Log "  Note: $($driverInfo.Error)" "WARN"
}

# Verify OSDriveLetter is available
if (-not $OSDriveLetter) {
    Write-Log "OSDriveLetter not set. Cannot determine destination drive." "ERROR"
    exit 1
}

# Copy/Extract drivers directly to OS drive
Write-Log "Starting driver copy/extract operation..." "INFO"
$copySuccess = Copy-DriversToOS -SourcePath $driverInfo.ModelPath -SourceType $driverInfo.Type -DestinationDrive $OSDriveLetter

# Final result
if ($copySuccess) {
    Write-Log "=== Copy-Drivers.ps1 Script Completed Successfully ===" "INFO"
    exit 0
} else {
    Write-Log "=== Copy-Drivers.ps1 Script Failed ===" "ERROR"
    exit 1
}
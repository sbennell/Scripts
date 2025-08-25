<#
.SYNOPSIS
Office 365 Detection Script for SCCM/Intune/MDM deployment

.DESCRIPTION
This script detects if Office 365 is installed and returns appropriate exit codes
- Exit Code 0: Office 365 is installed and meets requirements
- Exit Code 1: Office 365 is not installed or doesn't meet requirements

.NOTES
Compatible with SCCM Applications, Intune Win32 Apps, and other deployment systems
Author: IT Administrator
Date: 2025-08-20
Version: 1.0
#>

# Initialize variables
$DetectionResult = $false
$LogPath = "$env:TEMP\Office365Detection.log"

# Function to write log entries
function Write-DetectionLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogEntry
    Write-Output $LogEntry
}

try {
    Write-DetectionLog "Starting Office 365 detection..."
    
    # Method 1: Check for Office 365 via Registry (ClickToRun)
    Write-DetectionLog "Checking ClickToRun installation..."
    
    $ClickToRunPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    if (Test-Path $ClickToRunPath) {
        $ClickToRunInfo = Get-ItemProperty -Path $ClickToRunPath -ErrorAction SilentlyContinue
        
        if ($ClickToRunInfo) {
            $ProductIds = $ClickToRunInfo.ProductReleaseIds
            $Platform = $ClickToRunInfo.Platform
            $VersionToReport = $ClickToRunInfo.VersionToReport
            $UpdateChannel = $ClickToRunInfo.UpdateChannel
            
            Write-DetectionLog "Found ClickToRun installation:"
            Write-DetectionLog "  Product IDs: $ProductIds"
            Write-DetectionLog "  Platform: $Platform"
            Write-DetectionLog "  Version: $VersionToReport"
            Write-DetectionLog "  Update Channel: $UpdateChannel"
            
            # Check if it's Office 365/Microsoft 365
            if ($ProductIds -match "O365ProPlusRetail|O365BusinessRetail|O365HomePremRetail") {
                Write-DetectionLog "Office 365/Microsoft 365 detected via ClickToRun registry"
                $DetectionResult = $true
            }
        }
    }
    
    # Method 2: Check installed programs via WMI/CIM
    if (-not $DetectionResult) {
        Write-DetectionLog "Checking installed applications..."
        
        $Office365Apps = @()
        
        # Try CIM first (faster), fallback to WMI
        try {
            $Office365Apps = Get-CimInstance -ClassName Win32_Product -Filter "Name LIKE '%Microsoft 365%' OR Name LIKE '%Office 365%'" -ErrorAction Stop
        }
        catch {
            Write-DetectionLog "CIM failed, trying WMI..." "WARN"
            $Office365Apps = Get-WmiObject -Class Win32_Product -Filter "Name LIKE '%Microsoft 365%' OR Name LIKE '%Office 365%'" -ErrorAction SilentlyContinue
        }
        
        if ($Office365Apps) {
            foreach ($App in $Office365Apps) {
                Write-DetectionLog "Found application: $($App.Name) - Version: $($App.Version)"
                $DetectionResult = $true
            }
        }
    }
    
    # Method 3: Check registry uninstall keys (faster alternative)
    if (-not $DetectionResult) {
        Write-DetectionLog "Checking uninstall registry keys..."
        
        $UninstallPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($Path in $UninstallPaths) {
            $InstalledPrograms = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue | 
                Where-Object { $_.DisplayName -match "Microsoft 365|Office 365|Microsoft Office" -and 
                              $_.DisplayName -notmatch "Click-to-Run Extensibility|Microsoft Office File Validation" }
            
            if ($InstalledPrograms) {
                foreach ($Program in $InstalledPrograms) {
                    Write-DetectionLog "Found program: $($Program.DisplayName) - Version: $($Program.DisplayVersion)"
                    $DetectionResult = $true
                }
            }
        }
    }
    
    # Method 4: Check for Office executables
    if (-not $DetectionResult) {
        Write-DetectionLog "Checking for Office executables..."
        
        $OfficeExecutables = @(
            "${env:ProgramFiles}\Microsoft Office\root\Office16\WINWORD.EXE",
            "${env:ProgramFiles}\Microsoft Office\root\Office16\EXCEL.EXE",
            "${env:ProgramFiles}\Microsoft Office\root\Office16\POWERPNT.EXE",
            "${env:ProgramFiles}\Microsoft Office\root\Office16\OUTLOOK.EXE"
        )
        
        $FoundExecutables = 0
        foreach ($Executable in $OfficeExecutables) {
            if (Test-Path $Executable) {
                $FileInfo = Get-ItemProperty -Path $Executable
                Write-DetectionLog "Found executable: $Executable - Version: $($FileInfo.VersionInfo.FileVersion)"
                $FoundExecutables++
            }
        }
        
        # Consider Office installed if at least 3 core apps are found
        if ($FoundExecutables -ge 3) {
            Write-DetectionLog "Office 365 detected via executable files ($FoundExecutables/4 core apps found)"
            $DetectionResult = $true
        }
    }
    
    # Method 5: Check Office C2R Client
    if (-not $DetectionResult) {
        Write-DetectionLog "Checking for Office C2R Client..."
        
        $OfficeC2RClient = "${env:ProgramFiles}\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
        if (Test-Path $OfficeC2RClient) {
            Write-DetectionLog "Found Office ClickToRun client: $OfficeC2RClient"
            $DetectionResult = $true
        }
    }
    
    # Additional validation: Check if Office apps can be launched (optional)
    if ($DetectionResult) {
        Write-DetectionLog "Performing additional validation..."
        
        # Check if Word can be launched (quick test)
        $WordPath = "${env:ProgramFiles}\Microsoft Office\root\Office16\WINWORD.EXE"
        if (Test-Path $WordPath) {
            try {
                $WordVersion = (Get-ItemProperty -Path $WordPath).VersionInfo.ProductVersion
                Write-DetectionLog "Word version confirmed: $WordVersion"
            }
            catch {
                Write-DetectionLog "Could not verify Word version" "WARN"
            }
        }
    }
    
    # Final result
    if ($DetectionResult) {
        Write-DetectionLog "DETECTION SUCCESS: Office 365 is installed"
        Write-DetectionLog "Detection completed successfully"
        exit 0  # Success - Office 365 is installed
    }
    else {
        Write-DetectionLog "DETECTION FAILED: Office 365 is not installed"
        Write-DetectionLog "Detection completed - Office 365 not found"
        exit 1  # Failure - Office 365 is not installed
    }
}
catch {
    Write-DetectionLog "ERROR: Detection script failed - $($_.Exception.Message)" "ERROR"
    Write-DetectionLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1  # Failure due to error
}
finally {
    Write-DetectionLog "Detection script execution completed"
}
# Enhanced Detect if Symantec Endpoint Protection is installed
$LogFile = "$env:ProgramData\SEP_Detection.log"

Function Write-Log {
    param([string]$Message)
    $TimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $LogFile -Value "$TimeStamp - $Message" -ErrorAction SilentlyContinue
    Write-Host "$TimeStamp - $Message"
}

Write-Log "Starting SEP detection..."

# Search in both registry locations
$SEPFound = $false
$SEPInstalls = @()

$UninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($Path in $UninstallPaths) {
    Write-Log "Checking registry path: $Path"
    
    if (Test-Path $Path) {
        try {
            $Apps = Get-ChildItem $Path -ErrorAction SilentlyContinue |
                   Get-ItemProperty -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -like "*Symantec*Endpoint*Protection*" -or 
                                  $_.DisplayName -like "*SEP*" -or
                                  $_.Publisher -like "*Symantec*" }
            
            foreach ($App in $Apps) {
                if ($App.DisplayName) {
                    Write-Log "Found: $($App.DisplayName) - Version: $($App.DisplayVersion) - Code: $($App.PSChildName)"
                    $SEPInstalls += $App
                    $SEPFound = $true
                }
            }
        } catch {
            Write-Log "Error checking $Path : $_"
        }
    } else {
        Write-Log "Registry path not found: $Path"
    }
}

# Additional checks for SEP services and processes
Write-Log "Checking for SEP services..."
$SEPServices = Get-Service -Name "*Symantec*", "*SEP*" -ErrorAction SilentlyContinue
foreach ($Service in $SEPServices) {
    Write-Log "Found SEP service: $($Service.Name) - Status: $($Service.Status)"
    $SEPFound = $true
}

# Check for SEP processes
Write-Log "Checking for SEP processes..."
$SEPProcesses = Get-Process -Name "*Smc*", "*SEPM*", "*SymCorpUI*", "*ccSvcHst*" -ErrorAction SilentlyContinue
foreach ($Process in $SEPProcesses) {
    Write-Log "Found SEP process: $($Process.Name) - PID: $($Process.Id)"
    $SEPFound = $true
}

# Check for SEP installation directories
$SEPDirs = @(
    "${env:ProgramFiles}\Symantec",
    "${env:ProgramFiles(x86)}\Symantec",
    "${env:ProgramData}\Symantec"
)

foreach ($Dir in $SEPDirs) {
    if (Test-Path $Dir) {
        $SubDirs = Get-ChildItem $Dir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Endpoint*" }
        if ($SubDirs) {
            Write-Log "Found SEP directory: $Dir"
            $SEPFound = $true
        }
    }
}

# Final result
if ($SEPFound) {
    Write-Log "SEP DETECTED - Remediation required"
    if ($SEPInstalls.Count -gt 0) {
        Write-Log "Registry entries found: $($SEPInstalls.Count)"
        foreach ($Install in $SEPInstalls) {
            Write-Log "  - $($Install.DisplayName) [$($Install.PSChildName)]"
        }
    }
    exit 1  # Triggers remediation
} else {
    Write-Log "SEP NOT FOUND - System clean"
    exit 0
}
# MDT Registry Configuration Script
# Sets SOE (Standard Operating Environment) registry values from Task Sequence variables
# Version: 1.0.0
# Created: 2025-07-31
# Last Modified: 2025-07-31

# Script version information
$ScriptVersion = "1.0.0"
$ScriptName = "Sets-SOE-values.ps1"

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
    }
    
    # Write to log file if path is available
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

try {
    # Initialize the Task Sequence Environment COM object
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    
    # Get deployment share and computer name for logging
    $DeployShare = $tsenv.Value('DeployRoot')
    $OSDComputerName = $tsenv.Value('OSDComputerName')
    
    # Setup logging directory and file
    $LogDir = Join-Path $DeployShare "Logs\$OSDComputerName"
    $LogFile = Join-Path $LogDir "$ScriptName-$(Get-Date -Format 'yyyyMMdd').log"
    
    # Create log directory if it doesn't exist
    if (!(Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }
    
    # Set script-scoped log file variable
    $script:LogFile = $LogFile
    
    Write-Log -Message "========================================" -Level "INFO"
    Write-Log -Message "$ScriptName v$ScriptVersion started" -Level "INFO"
    Write-Log -Message "Computer Name: $OSDComputerName" -Level "INFO"
    Write-Log -Message "Deploy Share: $DeployShare" -Level "INFO"
    Write-Log -Message "Log File: $LogFile" -Level "INFO"
    Write-Log -Message "========================================" -Level "INFO"
    
    # Ensure the registry path exists
    $registryPath = 'HKLM:\Software\SOE'
    if (!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
        Write-Log -Message "Created registry path: $registryPath" -Level "INFO"
    } else {
        Write-Log -Message "Registry path already exists: $registryPath" -Level "INFO"
    }
    
    # Set school/organisation value from Task Sequence variable
    try {
        $orgValue = $tsenv.Value('organisation')
        if ($orgValue) {
            Set-ItemProperty -Path $registryPath -Name 'school' -Value $orgValue -Type String
            Write-Log -Message "Set school: $orgValue" -Level "INFO"
        } else {
            Write-Log -Message "Organisation variable is empty or not set" -Level "WARNING"
        }
    }
    catch {
        Write-Log -Message "Failed to set school value: $_" -Level "ERROR"
    }
    
    # Set image date to current date
    try {
        $imageDate = Get-Date -Format 'dd MMMM yyyy'
        Set-ItemProperty -Path $registryPath -Name 'imagedate' -Value $imageDate -Type String
        Write-Log -Message "Set imagedate: $imageDate" -Level "INFO"
    }
    catch {
        Write-Log -Message "Failed to set imagedate: $_" -Level "ERROR"
    }
    
    # Set deploy method from Task Sequence variable
    try {
        $deployMethod = $tsenv.Value('deploymethod')
        if ($deployMethod) {
            Set-ItemProperty -Path $registryPath -Name 'deploymethod' -Value $deployMethod -Type String
            Write-Log -Message "Set deploymethod: $deployMethod" -Level "INFO"
        } else {
            Write-Log -Message "Deploy method variable is empty or not set" -Level "WARNING"
        }
    }
    catch {
        Write-Log -Message "Failed to set deploymethod: $_" -Level "ERROR"
    }
    
    # Set image version from Task Sequence variable
    try {
        $imageVersion = $tsenv.Value('imageversion')
        if ($imageVersion) {
            Set-ItemProperty -Path $registryPath -Name 'imageversion' -Value $imageVersion -Type String
            Write-Log -Message "Set imageversion: $imageVersion" -Level "INFO"
        } else {
            Write-Log -Message "Image version variable is empty or not set" -Level "WARNING"
        }
    }
    catch {
        Write-Log -Message "Failed to set imageversion: $_" -Level "ERROR"
    }
    
    Write-Log -Message "Registry configuration completed successfully" -Level "INFO"
}
catch {
    Write-Log -Message "Failed to initialize Task Sequence Environment: $_" -Level "ERROR"
    exit 1
}
finally {
    Write-Log -Message "========================================" -Level "INFO"
    Write-Log -Message "$ScriptName v$ScriptVersion completed" -Level "INFO"
    Write-Log -Message "========================================" -Level "INFO"
}
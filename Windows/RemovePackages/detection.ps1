# Intune Win32 App Detection Script
# This script checks if the app removal process completed successfully

# Registry path and values to check
$registryPath = 'HKLM:\Software\SOE\RemovePackages'
$valueName = 'Version'
$expectedValue = '1.0.0'

try {
    # Check if registry key exists
    if (Test-Path $registryPath) {
        # Get the registry value
        $actualValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
        
        if ($actualValue -and $actualValue.$valueName -eq $expectedValue) {
            # Success: Registry key exists with correct value
            Write-Output "App removal script completed successfully. Version: $($actualValue.$valueName)"
            exit 0
        } else {
            # Registry key exists but value is incorrect or missing
            Write-Output "Registry key exists but version mismatch or missing value"
            exit 1
        }
    } else {
        # Registry key doesn't exist
        Write-Output "Registry key not found: $registryPath"
        exit 1
    }
} catch {
    # Error occurred during detection
    Write-Output "Error during detection: $($_.Exception.Message)"
    exit 1
}
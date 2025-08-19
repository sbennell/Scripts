# Intune Autopilot - Remove Unwanted Windows Apps
# This script removes specified Windows apps during Autopilot deployment

# Define apps to remove
$selectors = @(
    'Microsoft.BingSearch';
    'Microsoft.549981C3F5F10';
    'Microsoft.Windows.DevHome';
    'Microsoft.WindowsFeedbackHub';
    'Microsoft.GetHelp';
    'Microsoft.Getstarted';
    'Microsoft.WindowsMaps';
    'Microsoft.BingNews';
    'Microsoft.MicrosoftOfficeHub';
    'Microsoft.Office.OneNote';
    'Microsoft.OutlookForWindows';
    'Microsoft.People';
    'Microsoft.SkypeApp';
    'Microsoft.MicrosoftSolitaireCollection';
    'Microsoft.Wallet';
    'Microsoft.BingWeather';
    'Microsoft.Xbox.TCUI';
    'Microsoft.XboxApp';
    'Microsoft.XboxGameOverlay';
    'Microsoft.XboxGamingOverlay';
    'Microsoft.XboxIdentityProvider';
    'Microsoft.XboxSpeechToTextOverlay';
    'Microsoft.GamingApp';
    'Microsoft.YourPhone';
);

# Create log directory if it doesn't exist
$logDir = $env:TEMP
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force
}

$getCommand = {
    Get-AppxProvisionedPackage -Online;
};

$filterCommand = {
    $_.DisplayName -eq $selector;
};

$removeCommand = {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        $InputObject
    );
    process {
        $InputObject | Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction 'Continue';
    }
};

$type = 'Package';
$logfile = "$env:TEMP\RemovePackages.log";

# Create registry entry for detection
$registryPath = 'HKLM:\Software\SOE\RemovePackages'
if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}
Set-ItemProperty -Path $registryPath -Name "Version" -Value "1.0.0" -Type String

# Main execution block
& {
    Write-Output "Starting app removal process at $(Get-Date)"
    $installed = & $getCommand;
    
    foreach( $selector in $selectors ) {
        $result = [ordered] @{
            Selector = $selector;
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss";
        };
        
        $found = $installed | Where-Object -FilterScript $filterCommand;
        if( $found ) {
            Write-Output "Removing $selector..."
            $result.Output = $found | & $removeCommand;
            if( $? ) {
                $result.Message = "$type removed successfully.";
                Write-Output "✓ $selector removed"
            } else {
                $result.Message = "$type removal failed.";
                $result.Error = $Error[0];
                Write-Warning "✗ Failed to remove $selector"
            }
        } else {
            $result.Message = "$type not installed.";
            Write-Output "- $selector not found"
        }
        
        $result | ConvertTo-Json -Depth 3 -Compress;
    }
    
    Write-Output "App removal process completed at $(Get-Date)"
} *>&1 >> $logfile;
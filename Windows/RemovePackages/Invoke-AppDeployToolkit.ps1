<#

.SYNOPSIS
PSAppDeployToolkit - Windows App Removal for Intune Autopilot

.DESCRIPTION
This script removes unwanted Windows applications during Intune Autopilot deployment.
It uses the PSAppDeployToolkit framework for robust deployment handling.

.PARAMETER DeploymentType
The type of deployment to perform.

.PARAMETER DeployMode
Specifies whether the installation should be run in Interactive, Silent, NonInteractive, or Auto mode.

.PARAMETER SuppressRebootPassThru
Suppresses the 3010 return code (requires restart) from being passed back to the parent process.

.PARAMETER TerminalServerMode
Changes to "user install mode" and back to "user execute mode" for RDS/Citrix servers.

.PARAMETER DisableLogging
Disables logging to file for the script.

.EXAMPLE
powershell.exe -File Deploy-Application.ps1

.EXAMPLE
powershell.exe -File Deploy-Application.ps1 -DeployMode Silent

#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [System.String]$DeploymentType,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Auto', 'Interactive', 'NonInteractive', 'Silent')]
    [System.String]$DeployMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$SuppressRebootPassThru,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$TerminalServerMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$DisableLogging
)

##================================================
## MARK: Variables
##================================================

$adtSession = @{
    # App variables
    AppVendor = 'SOE'
    AppName = 'Windows App Removal'
    AppVersion = '1.0.0'
    AppArch = 'x64'
    AppLang = 'EN'
    AppRevision = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes = @(1641, 3010)
    AppProcessesToClose = @()
    AppScriptVersion = '1.0.0'
    AppScriptDate = '2025-08-19'
    AppScriptAuthor = 'SOE Admin'
    RequireAdmin = $true

    # Install Titles
    InstallName = 'Windows App Removal'
    InstallTitle = 'Removing Unwanted Windows Applications'

    # Script variables
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptParameters = $PSBoundParameters
    DeployAppScriptVersion = '4.1.0'
}

# Define apps to remove
$appsToRemove = @(
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
)

function Install-ADTDeployment
{
    [CmdletBinding()]
    param()

    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message
    Show-ADTInstallationWelcome -PersistPrompt

    ## Show Progress Message
    Show-ADTInstallationProgress -StatusMessage "Preparing to remove unwanted Windows applications..."

    ## Log deployment start
    Write-ADTLogEntry -Message "Starting Windows App Removal v$($adtSession.AppVersion)" -Severity 1

    ##================================================
    ## MARK: Install
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Get all provisioned packages
    Write-ADTLogEntry -Message "Scanning for provisioned packages..." -Severity 1
    Show-ADTInstallationProgress -StatusMessage "Scanning installed applications..."
    
    try {
        $installedPackages = Get-AppxProvisionedPackage -Online
        Write-ADTLogEntry -Message "Found $($installedPackages.Count) provisioned packages" -Severity 1
    }
    catch {
        Write-ADTLogEntry -Message "Failed to retrieve provisioned packages: $($_.Exception.Message)" -Severity 3
        throw
    }

    ## Remove specified apps
    $removedCount = 0
    $notFoundCount = 0
    $failedCount = 0

    foreach ($appName in $appsToRemove) {
        Show-ADTInstallationProgress -StatusMessage "Processing: $appName"
        Write-ADTLogEntry -Message "Processing app: $appName" -Severity 1
        
        $targetApp = $installedPackages | Where-Object { $_.DisplayName -eq $appName }
        
        if ($targetApp) {
            Write-ADTLogEntry -Message "Found $appName, attempting removal..." -Severity 1
            
            try {
                $targetApp | Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction Stop
                Write-ADTLogEntry -Message "Successfully removed: $appName" -Severity 1
                $removedCount++
            }
            catch {
                Write-ADTLogEntry -Message "Failed to remove $appName`: $($_.Exception.Message)" -Severity 2
                $failedCount++
            }
        }
        else {
            Write-ADTLogEntry -Message "$appName not found (already removed or not installed)" -Severity 1
            $notFoundCount++
        }
    }

    ## Log summary
    $summaryMessage = "App removal completed. Removed: $removedCount, Not Found: $notFoundCount, Failed: $failedCount"
    Write-ADTLogEntry -Message $summaryMessage -Severity 1

    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## Create registry key for detection
    Write-ADTLogEntry -Message "Creating detection registry entry..." -Severity 1
    Show-ADTInstallationProgress -StatusMessage "Finalizing installation..."
    
    try {
        $registryPath = 'HKLM:\Software\SOE\RemovePackages'
        
        if (!(Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
            Write-ADTLogEntry -Message "Created registry path: $registryPath" -Severity 1
        }
        
        Set-ItemProperty -Path $registryPath -Name "Version" -Value $adtSession.AppVersion -Type String
        Set-ItemProperty -Path $registryPath -Name "LastRun" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Type String
        Set-ItemProperty -Path $registryPath -Name "AppsRemoved" -Value $removedCount -Type DWord
        Set-ItemProperty -Path $registryPath -Name "AppsFailed" -Value $failedCount -Type DWord
        
        Write-ADTLogEntry -Message "Registry detection key created successfully" -Severity 1
    }
    catch {
        Write-ADTLogEntry -Message "Failed to create registry detection key: $($_.Exception.Message)" -Severity 2
    }

    ## Display completion message (only in interactive mode)
    if ($adtSession.DeployMode -eq 'Interactive') {
        Show-ADTInstallationPrompt -Message "Windows app removal completed successfully.`n`nRemoved: $removedCount apps`nNot Found: $notFoundCount apps`nFailed: $failedCount apps" -ButtonRightText 'OK' -Icon Information -NoWait
    }
}

function Uninstall-ADTDeployment
{
    [CmdletBinding()]
    param()

    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message
    Show-ADTInstallationWelcome -CloseProcessesCountdown 60

    ## Show Progress Message
    Show-ADTInstallationProgress -StatusMessage "Preparing to restore Windows applications..."

    ##================================================
    ## MARK: Uninstall
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Remove registry detection key
    Write-ADTLogEntry -Message "Removing detection registry entry..." -Severity 1
    Show-ADTInstallationProgress -StatusMessage "Cleaning up registry entries..."
    
    try {
        $registryPath = 'HKLM:\Software\SOE\RemovePackages'
        if (Test-Path $registryPath) {
            Remove-Item -Path $registryPath -Recurse -Force
            Write-ADTLogEntry -Message "Registry detection key removed successfully" -Severity 1
        }
    }
    catch {
        Write-ADTLogEntry -Message "Failed to remove registry detection key: $($_.Exception.Message)" -Severity 2
    }

    ##================================================
    ## MARK: Post-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    Write-ADTLogEntry -Message "Uninstall completed. Note: Removed apps will not be automatically restored." -Severity 1
}

function Repair-ADTDeployment
{
    [CmdletBinding()]
    param()

    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## Show Welcome Message
    Show-ADTInstallationWelcome -CloseProcessesCountdown 60

    ## Show Progress Message
    Show-ADTInstallationProgress -StatusMessage "Repairing Windows app removal..."

    ##================================================
    ## MARK: Repair
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## Re-run the install process
    Write-ADTLogEntry -Message "Repair initiated - re-running app removal process" -Severity 1
    Install-ADTDeployment

    ##================================================
    ## MARK: Post-Repair
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    Write-ADTLogEntry -Message "Repair process completed" -Severity 1
}

##================================================
## MARK: Initialization
##================================================

# Set strict error handling across entire operation.
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
Set-StrictMode -Version 1

# Import the module and instantiate a new session.
try
{
    # Import the module locally if available, otherwise try to find it from PSModulePath.
    if (Test-Path -LiteralPath "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1" -PathType Leaf)
    {
        Get-ChildItem -LiteralPath "$PSScriptRoot\PSAppDeployToolkit" -Recurse -File | Unblock-File -ErrorAction Ignore
        Import-Module -FullyQualifiedName @{ ModuleName = "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.0' } -Force
    }
    else
    {
        Import-Module -FullyQualifiedName @{ ModuleName = 'PSAppDeployToolkit'; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.0' } -Force
    }

    # Open a new deployment session
    $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
    $adtSession = Remove-ADTHashtableNullOrEmptyValues -Hashtable $adtSession
    $adtSession = Open-ADTSession @adtSession @iadtParams -PassThru
}
catch
{
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
    exit 60008
}

##================================================
## MARK: Invocation
##================================================

# Commence the actual deployment operation.
try
{
    # Import any found extensions before proceeding with the deployment.
    Get-ChildItem -LiteralPath $PSScriptRoot -Directory | & {
        process
        {
            if ($_.Name -match 'PSAppDeployToolkit\..+$')
            {
                Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Unblock-File -ErrorAction Ignore
                Import-Module -Name $_.FullName -Force
            }
        }
    }

    # Invoke the deployment and close out the session.
    & "$($adtSession.DeploymentType)-ADTDeployment"
    Close-ADTSession
}
catch
{
    # An unhandled error has been caught.
    $mainErrorMessage = "An unhandled error within [$($MyInvocation.MyCommand.Name)] has occurred.`n$(Resolve-ADTErrorRecord -ErrorRecord $_)"
    Write-ADTLogEntry -Message $mainErrorMessage -Severity 3

    Close-ADTSession -ExitCode 60001
}
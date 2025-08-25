<#
.SYNOPSIS
PSAppDeployToolkit - Office 365 deployment script using PSADT 4.1

.DESCRIPTION
This script performs the installation, uninstallation, or repair of Microsoft Office 365 using the Office Deployment Tool (ODT).

.PARAMETER DeploymentType
The type of deployment to perform: Install, Uninstall, or Repair

.PARAMETER DeployMode
Deployment mode: Auto, Interactive, NonInteractive, or Silent

.EXAMPLE
powershell.exe -File Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent

.NOTES
- Requires Office Deployment Tool (setup.exe) in the Files folder
- Requires configuration.xml in the Files folder
- For enterprise deployment of Office 365
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
    AppVendor = 'Microsoft'
    AppName = 'Office 365'
    AppVersion = '2024'
    AppArch = 'x64'
    AppLang = 'EN'
    AppRevision = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes = @(1641, 3010)
    AppProcessesToClose = @(
        @{ Name = 'winword'; Description = 'Microsoft Word' },
        @{ Name = 'excel'; Description = 'Microsoft Excel' },
        @{ Name = 'powerpnt'; Description = 'Microsoft PowerPoint' },
        @{ Name = 'outlook'; Description = 'Microsoft Outlook' },
        @{ Name = 'onenote'; Description = 'Microsoft OneNote' },
        @{ Name = 'msaccess'; Description = 'Microsoft Access' },
        @{ Name = 'mspub'; Description = 'Microsoft Publisher' },
        @{ Name = 'visio'; Description = 'Microsoft Visio' },
        @{ Name = 'winproj'; Description = 'Microsoft Project' },
        @{ Name = 'teams'; Description = 'Microsoft Teams' },
        @{ Name = 'lync'; Description = 'Skype for Business' }
    )
    AppScriptVersion = '1.0.0'
    AppScriptDate = '2025-08-20'
    AppScriptAuthor = 'IT Administrator'
    RequireAdmin = $true

    # Install Titles
    InstallName = 'Microsoft Office 365'
    InstallTitle = 'Microsoft Office 365 Installation'

    # Script variables
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptParameters = $PSBoundParameters
    DeployAppScriptVersion = '4.1.0'
}

function Install-ADTDeployment
{
    [CmdletBinding()]
    param()

    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    # Show Welcome Message
    Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

    # Show Progress Message
    Show-ADTInstallationProgress -StatusMessage "Preparing Office 365 installation..."

    # Define paths
    $ODTPath = Join-Path -Path $adtSession.DirFiles -ChildPath 'setup.exe'
    $ConfigPath = Join-Path -Path $adtSession.DirFiles -ChildPath 'configuration.xml'
    $Office365SourcePath = Join-Path -Path $adtSession.DirFiles -ChildPath 'Office365'

    # Verify ODT and configuration files exist
    if (!(Test-Path -Path $ODTPath))
    {
        Write-ADTLogEntry -Message "Office Deployment Tool (setup.exe) not found in Files folder" -Severity 3
        Show-ADTInstallationPrompt -Message "Installation files are missing. Please contact your IT administrator." -ButtonRightText 'OK' -Icon Error
        Exit-ADTFunction -ExitCode 60001
    }

    if (!(Test-Path -Path $ConfigPath))
    {
        Write-ADTLogEntry -Message "Configuration.xml not found in Files folder" -Severity 3
        Show-ADTInstallationPrompt -Message "Configuration files are missing. Please contact your IT administrator." -ButtonRightText 'OK' -Icon Error
        Exit-ADTFunction -ExitCode 60001
    }

    # Check for existing Office installations
    Write-ADTLogEntry -Message "Checking for existing Office installations..."
    $ExistingOffice = Get-ADTApplication -Name 'Microsoft Office*' -IncludeUpdatesAndHotfixes:$false
    
    if ($ExistingOffice)
    {
        Write-ADTLogEntry -Message "Found existing Office installation(s): $($ExistingOffice.DisplayName -join ', ')"
        Show-ADTInstallationProgress -StatusMessage "Removing previous Office installations..."
        
        # Remove existing Office installations
        foreach ($Office in $ExistingOffice)
        {
            Write-ADTLogEntry -Message "Removing $($Office.DisplayName)..."
            if ($Office.UninstallString -match 'msiexec')
            {
                $ProductCode = ($Office.UninstallString -split '/X')[1].Trim()
                Start-ADTMsiProcess -Action Uninstall -Path $ProductCode -Parameters '/qn /norestart'
            }
        }
    }

    ##================================================
    ## MARK: Install
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    # Download Office 365 if source files don't exist
    if (!(Test-Path -Path $Office365SourcePath))
    {
        Write-ADTLogEntry -Message "Downloading Office 365 installation files..."
        Show-ADTInstallationProgress -StatusMessage "Downloading Office 365. This may take several minutes..."
        
        $DownloadParams = "/download `"$ConfigPath`""
        $DownloadResult = Start-ADTProcess -FilePath $ODTPath -Parameters $DownloadParams -WindowStyle Hidden -PassThru
        
        if ($DownloadResult.ExitCode -ne 0)
        {
            Write-ADTLogEntry -Message "Office 365 download failed with exit code: $($DownloadResult.ExitCode)" -Severity 3
            Show-ADTInstallationPrompt -Message "Failed to download Office 365. Please check your internet connection." -ButtonRightText 'OK' -Icon Error
            Exit-ADTFunction -ExitCode $DownloadResult.ExitCode
        }
    }

    # Install Office 365
    Write-ADTLogEntry -Message "Installing Office 365..."
    Show-ADTInstallationProgress -StatusMessage "Installing Office 365. Please wait..."

    $InstallParams = "/configure `"$ConfigPath`""
    $InstallResult = Start-ADTProcess -FilePath $ODTPath -Parameters $InstallParams -WindowStyle Hidden -PassThru

    if ($InstallResult.ExitCode -eq 0)
    {
        Write-ADTLogEntry -Message "Office 365 installation completed successfully"
    }
    elseif ($InstallResult.ExitCode -eq 3010)
    {
        Write-ADTLogEntry -Message "Office 365 installation completed successfully. Reboot required." -Severity 2
    }
    else
    {
        Write-ADTLogEntry -Message "Office 365 installation failed with exit code: $($InstallResult.ExitCode)" -Severity 3
        Show-ADTInstallationPrompt -Message "Office 365 installation failed. Please contact your IT administrator." -ButtonRightText 'OK' -Icon Error
        Exit-ADTFunction -ExitCode $InstallResult.ExitCode
    }

    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    # Verify installation
    Write-ADTLogEntry -Message "Verifying Office 365 installation..."
    Start-Sleep -Seconds 10  # Wait for registration to complete
    
    $OfficeVerification = Get-ADTApplication -Name 'Microsoft 365*' -IncludeUpdatesAndHotfixes:$false
    if (!$OfficeVerification)
    {
        # Try alternative search patterns
        $OfficeVerification = Get-ADTApplication -Name '*Office 365*' -IncludeUpdatesAndHotfixes:$false
    }
    
    if ($OfficeVerification)
    {
        Write-ADTLogEntry -Message "Office 365 installation verified: $($OfficeVerification.DisplayName)"
    }
    else
    {
        Write-ADTLogEntry -Message "Office 365 installation verification failed" -Severity 2
    }

    # Configure Office 365 settings
    Write-ADTLogEntry -Message "Applying Office 365 configuration settings..."

    # Show completion message
    if ($adtSession.DeployMode -ne 'Silent')
    {
        Show-ADTInstallationPrompt -Message 'Office 365 has been successfully installed.' -ButtonRightText 'OK' -Icon Information -NoWait
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

    # Show Welcome Message
    Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -CloseProcessesCountdown 60

    # Show Progress Message
    Show-ADTInstallationProgress -StatusMessage "Preparing to uninstall Office 365..."

    # Define paths
    $ODTPath = Join-Path -Path $adtSession.DirFiles -ChildPath 'setup.exe'

    ##================================================
    ## MARK: Uninstall
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    # Create uninstall configuration
    Write-ADTLogEntry -Message "Creating uninstall configuration..."
    
    $UninstallConfig = @'
<Configuration>
  <Remove All="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
'@

    $UninstallConfigPath = Join-Path -Path $adtSession.DirFiles -ChildPath 'uninstall.xml'
    $UninstallConfig | Out-File -FilePath $UninstallConfigPath -Encoding UTF8

    # Uninstall Office 365
    Write-ADTLogEntry -Message "Uninstalling Office 365..."
    Show-ADTInstallationProgress -StatusMessage "Uninstalling Office 365..."

    if (Test-Path -Path $ODTPath)
    {
        $UninstallParams = "/configure `"$UninstallConfigPath`""
        $UninstallResult = Start-ADTProcess -FilePath $ODTPath -Parameters $UninstallParams -WindowStyle Hidden -PassThru

        if ($UninstallResult.ExitCode -eq 0)
        {
            Write-ADTLogEntry -Message "Office 365 uninstallation completed successfully"
        }
        else
        {
            Write-ADTLogEntry -Message "Office 365 uninstallation failed with exit code: $($UninstallResult.ExitCode)" -Severity 3
        }
    }
    else
    {
        Write-ADTLogEntry -Message "ODT not found, attempting MSI-based removal..."
        $OfficeApps = Get-ADTApplication -Name 'Microsoft 365*' -IncludeUpdatesAndHotfixes:$false
        foreach ($App in $OfficeApps)
        {
            if ($App.UninstallString -match 'msiexec')
            {
                $ProductCode = ($App.UninstallString -split '/X')[1].Trim()
                Start-ADTMsiProcess -Action Uninstall -Path $ProductCode -Parameters '/qn /norestart'
            }
        }
    }

    ##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    # Clean up registry entries
    Write-ADTLogEntry -Message "Cleaning up Office 365 registry entries..."
    Remove-ADTRegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\16.0' -Recurse -SilentlyContinue

    # Remove temporary files
    if (Test-Path -Path $UninstallConfigPath)
    {
        Remove-Item -Path $UninstallConfigPath -Force -ErrorAction SilentlyContinue
    }

    Write-ADTLogEntry -Message "Office 365 uninstallation process completed"
}

function Repair-ADTDeployment
{
    [CmdletBinding()]
    param()

    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    # Show Welcome Message
    Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -CloseProcessesCountdown 60

    # Show Progress Message
    Show-ADTInstallationProgress -StatusMessage "Preparing to repair Office 365..."

    ##================================================
    ## MARK: Repair
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    # Office 365 repair using Quick Repair
    Write-ADTLogEntry -Message "Performing Office 365 Quick Repair..."
    Show-ADTInstallationProgress -StatusMessage "Repairing Office 365..."

    # Use OfficeC2RClient.exe for repair
    $OfficeC2RPath = "${env:ProgramFiles}\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
    
    if (Test-Path -Path $OfficeC2RPath)
    {
        $RepairResult = Start-ADTProcess -FilePath $OfficeC2RPath -Parameters '/update user displaylevel=false forceappshutdown=true' -WindowStyle Hidden -PassThru
        
        if ($RepairResult.ExitCode -eq 0)
        {
            Write-ADTLogEntry -Message "Office 365 repair completed successfully"
        }
        else
        {
            Write-ADTLogEntry -Message "Office 365 repair failed with exit code: $($RepairResult.ExitCode)" -Severity 3
        }
    }
    else
    {
        Write-ADTLogEntry -Message "OfficeC2RClient.exe not found. Office 365 may not be installed." -Severity 3
        Exit-ADTFunction -ExitCode 60001
    }

    ##================================================
    ## MARK: Post-Repair
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    Write-ADTLogEntry -Message "Office 365 repair process completed"
}

##================================================
## MARK: Initialization
##================================================

# Set strict error handling
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
Set-StrictMode -Version 1

# Import the module and instantiate a new session
try
{
    if (Test-Path -LiteralPath "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1" -PathType Leaf)
    {
        Get-ChildItem -LiteralPath "$PSScriptRoot\PSAppDeployToolkit" -Recurse -File | Unblock-File -ErrorAction Ignore
        Import-Module -FullyQualifiedName @{ ModuleName = "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.0' } -Force
    }
    else
    {
        Import-Module -FullyQualifiedName @{ ModuleName = 'PSAppDeployToolkit'; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.1.0' } -Force
    }

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

try
{
    # Import extensions
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

    # Invoke deployment
    & "$($adtSession.DeploymentType)-ADTDeployment"
    Close-ADTSession
}
catch
{
    $mainErrorMessage = "An unhandled error within [$($MyInvocation.MyCommand.Name)] has occurred.`n$(Resolve-ADTErrorRecord -ErrorRecord $_)"
    Write-ADTLogEntry -Message $mainErrorMessage -Severity 3
    Close-ADTSession -ExitCode 60001
}
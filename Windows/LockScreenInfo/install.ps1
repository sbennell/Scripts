#Requires -RunAsAdministrator

# Install script for LockScreenInfo deployment
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = "Contact information to display")]
    [string]$ContactInfo = "For help, contact IT support",

    [Parameter(Mandatory = $false, HelpMessage = "Organization name to display")]
    [string]$Organization = "",

    [Parameter(Mandatory = $false, HelpMessage = "Hide organization name")]
    [switch]$HideOrganization,

    [Parameter(Mandatory = $false, HelpMessage = "Hide contact information")]
    [switch]$HideContact,

    [Parameter(Mandatory = $false, HelpMessage = "HTML template to use")]
    [ValidateSet("format_bottom_left.html", "format_Bottom_Right.html", "format_top_left.html", "format_top_right.html")]
    [string]$HTMLPath = "format_Bottom_Right.html",

    [Parameter(Mandatory = $false, HelpMessage = "Background image filename")]
    [string]$BackgroundImage = "c:\windows\OEMFiles\Wallpaper\wallpaper.jpg",

    [Parameter(Mandatory = $false, HelpMessage = "Base font size multiplier")]
    [double]$FontSizeMultiplier = 1.0,

    [Parameter(Mandatory = $false, HelpMessage = "Additional custom parameters for the script")]
    [string]$CustomParameters = ""
)

$ErrorActionPreference = "Stop"
$LogPath = "C:\Windows\OEMFiles\logs\LockScreenInfo_Install.log"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogPath -Append
    Write-Host $Message
}

try {
    Write-Log "Starting LockScreenInfo installation..."
    Write-Log "Parameters received:"
    Write-Log "  ContactInfo: $ContactInfo"
    Write-Log "  Organization: $Organization"
    Write-Log "  HideOrganization: $HideOrganization"
    Write-Log "  HideContact: $HideContact"
    Write-Log "  HTMLPath: $HTMLPath"
    Write-Log "  BackgroundImage: $BackgroundImage"
    Write-Log "  FontSizeMultiplier: $FontSizeMultiplier"
    Write-Log "  CustomParameters: $CustomParameters"
    
    # Create directory structure
    $Scriptsdir = "C:\Windows\OEMFiles\Scripts"
    $LockScreenInfo_dir = "C:\Windows\OEMFiles\Scripts\LockScreenInfo"
    $LockscreenDir = "C:\Windows\OEMFiles\lockscreen"
    $LogsDir = "C:\Windows\OEMFiles\logs"
    
    @($Scriptsdir, $LockScreenInfo_dir, $LockscreenDir, $LogsDir) | ForEach-Object {
        if (!(Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-Log "Created directory: $_"
        }
    }
    
    # Copy script files
    $SourceFiles = @(
    "LockScreenInfo.ps1",
    "format_bottom_left.html",
    "format_Bottom_Right.html",
    "format_top_left.html",
    "format_top_right.html",
    "wkhtmltoimage.exe",
    "wkhtmltox.dll",
    "libwkhtmltox.a",
    "LICENSE",
    "readme.md"
	)
    
foreach ($file in $SourceFiles) {
    $Source = Join-Path $PSScriptRoot $file
    $Destination = Join-Path $LockScreenInfo_dir $file

    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Log "Copied $file to $Destination"
    } else {
        Write-Log "Warning: Source file $file not found"
    }
}
    
    # Create scheduled task with dynamic parameters
    $TaskName = "LockScreenInfo"
    
    # Build task arguments dynamically
    $TaskArgs = @(
        '-ExecutionPolicy', 'Bypass',
        '-NonInteractive',
        '-WindowStyle', 'Hidden',
        '-File', "$LockScreenInfo_dir\LockScreenInfo.ps1"
    )
    
    # Add conditional parameters
    if ($HideOrganization) {
        $TaskArgs += '-HideOrganization'
        Write-Log "  Added: -HideOrganization"
    } elseif ($Organization) {
        $TaskArgs += "-Organization `"$Organization`""
        Write-Log "  Added: -Organization `"$Organization`""
    }
    
    if ($HideContact) {
        $TaskArgs += '-HideContact'
        Write-Log "  Added: -HideContact"
    } else {
        $TaskArgs += "-ContactInfo `"$ContactInfo`""
        Write-Log "  Added: -ContactInfo `"$ContactInfo`""
    }
    
    # Add standard parameters
    $TaskArgs += "-BackgroundImage `"$BackgroundImage`""
    $TaskArgs += '-TargetImage "C:\Windows\OEMFiles\lockscreen\lockscreen.jpg"'
    $TaskArgs += "-HTMLPath `"$HTMLPath`""
    $TaskArgs += "-FontSizeMultiplier $FontSizeMultiplier"
    
    # Add any custom parameters
    if ($CustomParameters) {
        $TaskArgs += $CustomParameters
        Write-Log "  Added custom parameters: $CustomParameters"
    }
    
    $TaskArgsString = $TaskArgs -join ' '
    Write-Log "Final task arguments: $TaskArgsString"
    
    # Remove existing task if it exists
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Log "Removed existing scheduled task: $TaskName"
    }
    
    # Create new scheduled task
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $TaskArgsString -WorkingDirectory $LockScreenInfo_dir
    $Trigger1 = New-ScheduledTaskTrigger -AtLogOn
    $Trigger2 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00"
    
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    $Task = New-ScheduledTask -Action $Action -Trigger @($Trigger1, $Trigger2) -Settings $Settings -Principal $Principal -Description "Updates lock screen with system information - runs weekly on Monday at 9:00 AM and at startup"
    
    Register-ScheduledTask -TaskName $TaskName -InputObject $Task | Out-Null
    Write-Log "Created scheduled task: $TaskName"
    
    # Run the script once immediately to generate initial lock screen
    Write-Log "Running initial lock screen generation..."
    Start-Process -FilePath "powershell.exe" -ArgumentList $TaskArgs -Wait -WindowStyle Hidden

    # Verify installation
    $RequiredFiles = @(
        "$LockScreenInfo_dir\LockScreenInfo.ps1",
        "$LockScreenInfo_dir\format_bottom_left.html",
        "$LockScreenInfo_dir\format_Bottom_Right.html",
        "$LockScreenInfo_dir\format_top_left.html",
        "$LockScreenInfo_dir\format_top_right.html",
        "$LockScreenInfo_dir\wkhtmltoimage.exe",
        "$LockScreenInfo_dir\wkhtmltox.dll",
        "$LockScreenInfo_dir\libwkhtmltox.a"
    )
    
    $MissingFiles = $RequiredFiles | Where-Object { !(Test-Path $_) }
    if ($MissingFiles) {
        throw "Installation incomplete. Missing files: $($MissingFiles -join ', ')"
    }
    
    if (!(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
        throw "Scheduled task creation failed"
    }
    
    Write-Log "LockScreenInfo installation completed successfully"
    exit 0
    
} catch {
    Write-Log "Installation failed: $($_.Exception.Message)"
    exit 1
}
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs LockScreenInfo: copies files, sets registry, creates scheduled task, and triggers initial lock screen.
#>

# --- Script Version ---
$LockScreenVersion = "1.3.2"

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
    [string]$BackgroundImage = "C:\Windows\OEMFiles\Wallpaper\wallpaper.jpg",

    [Parameter(Mandatory = $false, HelpMessage = "Target lock screen image filename")]
    [string]$TargetImage = "C:\Windows\OEMFiles\LockScreen\lockscreen.jpg",

    [Parameter(Mandatory = $false, HelpMessage = "Base font size multiplier")]
    [double]$FontSizeMultiplier = 1.0
)

# --- Logging ---
$LogFolder = "C:\Windows\OEMFiles\logs"
$LogFile   = Join-Path $LogFolder "LockScreenInfo_Install.log"
if (-not (Test-Path $LogFolder)) { New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = "$timestamp - $Message"
    Write-Host $fullMessage -ForegroundColor Yellow
    Add-Content -Path $LogFile -Value $fullMessage
}

Write-Log "Starting LockScreenInfo installation..."

# --- Folder setup ---
$Destination = "C:\Windows\OEMFiles\Script\LockScreenInfo"
$parentFolders = @("C:\Windows\OEMFiles", "C:\Windows\OEMFiles\Script", $Destination)
foreach ($folder in $parentFolders) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Log "Created folder structure: $folder"
    }
}

# --- Copy files ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SourceFiles = Join-Path $ScriptDir "Files"
Write-Log "Copying files from $SourceFiles to $Destination..."
Copy-Item -Path "$SourceFiles\*" -Destination $Destination -Recurse -Force
Write-Log "Files copied successfully."

# --- Registry for Intune detection ---
Write-Log "Adding registry key for Intune detection..."
$RegPath = "HKLM:\Software\SOE\LockScreenInfo"
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
    Write-Log "Created registry path: $RegPath"
}

New-ItemProperty -Path $RegPath -Name "Version" -Value $LockScreenVersion -PropertyType String -Force | Out-Null
Write-Log "Set Version = $LockScreenVersion in $RegPath"

# --- Build Scheduled Task ---
$TaskName = "LockScreenInfo"
$TaskArgs = @(
    '-ExecutionPolicy', 'Bypass',
    '-NonInteractive',
    '-WindowStyle', 'Hidden',
    '-File', "$Destination\LockScreenInfo.ps1"
)

# Conditional parameters
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

# Standard parameters with logging
$TaskArgs += "-BackgroundImage `"$BackgroundImage`""
Write-Log "  Added: -BackgroundImage `"$BackgroundImage`""

$TaskArgs += "-TargetImage `"$TargetImage`""
Write-Log "  Added: -TargetImage `"$TargetImage`""

$TaskArgs += "-HTMLPath `"$HTMLPath`""
Write-Log "  Added: -HTMLPath `"$HTMLPath`""

$TaskArgs += "-FontSizeMultiplier $FontSizeMultiplier"
Write-Log "  Added: -FontSizeMultiplier $FontSizeMultiplier"

$TaskArgsString = $TaskArgs -join ' '
Write-Log "Final task arguments: $TaskArgsString"

# Remove existing task if exists
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Log "Removed existing scheduled task: $TaskName"
}

# Create scheduled task
$Action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $TaskArgsString -WorkingDirectory $Destination
$Trigger1  = New-ScheduledTaskTrigger -AtLogOn
$Trigger2  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00"
$Settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Task      = New-ScheduledTask -Action $Action -Trigger @($Trigger1, $Trigger2) -Settings $Settings -Principal $Principal -Description "Updates lock screen with system information - runs weekly on Monday at 9:00 AM and at startup"
Register-ScheduledTask -TaskName $TaskName -InputObject $Task | Out-Null
Write-Log "Created scheduled task: $TaskName"

# --- Trigger initial lock screen via scheduled task ---
Write-Log "Triggering initial lock screen generation via scheduled task..."
Start-ScheduledTask -TaskName $TaskName
Write-Log "Initial lock screen task triggered."

Write-Log "LockScreenInfo installation completed successfully."

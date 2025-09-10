# Requires -RunAsAdministrator
<#
    .NOTES
    ===========================================================================
    Created on:    4/3/2025
    Last Updated:  27-8-2025
    Version:       27.08.25.4 
    Author:        Stewart Bennell (Modified - Online Only Version)
    Filename:      install-LanguagePacks-Online-Only.ps1
    ===========================================================================
    .SYNOPSIS
    Online-only script that configures Australian English language settings
    including display language using modern Install-Language cmdlet with comprehensive 
    registry configuration for Intune deployment.
    
    .DESCRIPTION
    This script installs language packs via Microsoft Store using Install-Language
    with comprehensive registry configuration for default user profiles.
    Offline CAB installation functionality has been removed.
#>

param(
    [string]$LanguageSetting = "en-AU",
    [int]$GeoId = 12,
    [string]$UILanguage = "en-AU"  # Using Australian English for UI consistency
)

# Handle 32-bit vs 64-bit PowerShell issue in Intune
Write-Host "Is 64bit PowerShell: $([Environment]::Is64BitProcess)" -ForegroundColor Cyan
Write-Host "Is 64bit OS: $([Environment]::Is64BitOperatingSystem)" -ForegroundColor Cyan

if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    $TranscriptPath = [IO.Path]::Combine($env:ProgramData, "Scripts", "LanguageSetup", "InstallLog_x86.txt")
    New-Item -Path (Split-Path $TranscriptPath) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    Start-Transcript -Path $TranscriptPath -Force -IncludeInvocationHeader
    Write-Warning "Running in 32-bit PowerShell, switching to 64-bit..."
    
    if ($myInvocation.Line) {
        & "$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    } else {
        & "$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
    Stop-Transcript
    exit $lastexitcode
}

# Ensure script is running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script requires running as Administrator"
    exit 1
}

# Setup logging
$logDir = [IO.Path]::Combine($env:ProgramData, "Scripts", "LanguageSetup")
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logPath = Join-Path $logDir "InstallLog.txt"
Start-Transcript -Path $logPath -Force -IncludeInvocationHeader

$RebootRequired = $false
$InstallationSuccessful = $true

Write-Host "Starting language configuration for: $LanguageSetting" -ForegroundColor Green
Write-Host "UI Language: $UILanguage | GeoId: $GeoId" -ForegroundColor Cyan

try {
    # Import required modules
    Write-Host "Importing required modules..." -ForegroundColor Yellow
    Import-Module International -ErrorAction Stop
    
    try {
        Import-Module LanguagePackManagement -ErrorAction Stop
        Write-Host "LanguagePackManagement module loaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "LanguagePackManagement module not available. This script requires online connectivity and the module to function."
        $InstallationSuccessful = $false
        throw
    }

    # Modern Install-Language (Online Method) - Always attempt installation
    Write-Host "Using modern Install-Language method..." -ForegroundColor Yellow
    
    # Install primary language pack (en-AU) - removed pre-check, let Install-Language handle it
    Write-Host "Installing/ensuring primary language pack: $LanguageSetting" -ForegroundColor Yellow
    try {
        Install-Language -Language $LanguageSetting -CopyToSettings -ErrorAction Stop
        Write-Host "Primary language pack installation completed" -ForegroundColor Green
        $RebootRequired = $true
    }
    catch {
        Write-Error "Install-Language failed for $LanguageSetting : $($_.Exception.Message)"
        $InstallationSuccessful = $false
        throw
    }

    # Install UI language pack (en-AU for display) - only if different from primary
    if ($UILanguage -ne $LanguageSetting) {
        Write-Host "Installing/ensuring UI language pack: $UILanguage" -ForegroundColor Yellow
        try {
            Install-Language -Language $UILanguage -CopyToSettings -ErrorAction Stop
            Write-Host "UI language pack installation completed" -ForegroundColor Green
            $RebootRequired = $true
        }
        catch {
            Write-Error "Install-Language failed for UI language $UILanguage : $($_.Exception.Message)"
            $InstallationSuccessful = $false
            throw
        }
    }
    else {
        Write-Host "Primary and UI languages are the same: $LanguageSetting" -ForegroundColor Cyan
    }

    # Wait for language packs to be fully registered
    Write-Host "Waiting for language packs to be registered..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    # Configure system settings
    Write-Host "`nConfiguring system language settings..." -ForegroundColor Green

    # System Locale
    if ($(Get-WinSystemLocale).Name -ne $LanguageSetting) {
        Write-Host "Setting system locale to: $LanguageSetting" -ForegroundColor Yellow
        Set-WinSystemLocale -SystemLocale $LanguageSetting
        $RebootRequired = $true
    }

    # Culture
    if ($(Get-Culture).Name -ne $LanguageSetting) {
        Write-Host "Setting system culture to: $LanguageSetting" -ForegroundColor Yellow
        Set-Culture -CultureInfo $LanguageSetting
        $RebootRequired = $true
    }

    # Home Location
    if ($(Get-WinHomeLocation).GeoId -ne $GeoId) {
        Write-Host "Setting home location to GeoId: $GeoId" -ForegroundColor Yellow
        Set-WinHomeLocation -GeoId $GeoId
        $RebootRequired = $true
    }

    # User Language List - Set to Australian English
    Write-Host "Configuring user language list..." -ForegroundColor Yellow
    try {
        Set-WinUserLanguageList $LanguageSetting -Force
        Write-Host "User language list set to: $LanguageSetting" -ForegroundColor Green
        $RebootRequired = $true
    }
    catch {
        Write-Warning "Could not set user language list: $($_.Exception.Message)"
        # Try alternative method
        try {
            $languageList = New-WinUserLanguageList -Language $LanguageSetting
            Set-WinUserLanguageList -LanguageList $languageList -Force
            Write-Host "User language list configured (alternative method)" -ForegroundColor Yellow
            $RebootRequired = $true
        }
        catch {
            Write-Error "Failed to set user language list: $($_.Exception.Message)"
        }
    }

    # UI Language Configuration
    Write-Host "Configuring display/UI language..." -ForegroundColor Yellow
    try {
        # First, ensure the UI language is in the user language list
        $currentLanguages = Get-WinUserLanguageList
        $uiLanguageInList = $currentLanguages | Where-Object { $_.LanguageTag -eq $UILanguage }
        
        if ($uiLanguageInList) {
            # Set system preferred UI language
            $currentUILang = Get-SystemPreferredUILanguage -ErrorAction SilentlyContinue
            if ($currentUILang -ne $UILanguage) {
                Write-Host "Setting system preferred UI language to: $UILanguage" -ForegroundColor Yellow
                Set-SystemPreferredUILanguage -Language $UILanguage
                $RebootRequired = $true
            }
            
            # Set UI language override
            Write-Host "Setting UI language override to: $UILanguage" -ForegroundColor Yellow
            Set-WinUILanguageOverride -Language $UILanguage
            $RebootRequired = $true
        }
        else {
            Write-Warning "UI Language $UILanguage not found in user language list, cannot set as display language"
        }
    }
    catch {
        Write-Warning "Could not set UI language: $($_.Exception.Message)"
    }

    # Set timezone
    Write-Host "Setting timezone to Australian Eastern Standard Time..." -ForegroundColor Yellow
    & tzutil /s "AUS Eastern Standard Time"

    # Culture opt-out
    Write-Host "Configuring culture-based language list opt-out..." -ForegroundColor Yellow
    Set-WinCultureFromLanguageListOptOut -OptOut $true

    # Configure default user profile
    Write-Host "`nConfiguring default user profile..." -ForegroundColor Green
    
    # Configure the default user profile registry settings
    # Load the default user hive
    reg load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"
    
    # Set default locale for new users
    reg add "HKU\DefaultUser\Control Panel\International" /v "LocaleName" /t REG_SZ /d "en-AU" /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sCountry" /t REG_SZ /d "Australia" /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sLanguage" /t REG_SZ /d "ENA" /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sLongDate" /t REG_SZ /d "d MMMM yyyy" /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sShortDate" /t REG_SZ /d "d/MM/yyyy" /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sTimeFormat" /t REG_SZ /d "h:mm:ss tt" /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "iCountry" /t REG_SZ /d "61" /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sDecimal" /t REG_SZ /d "." /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sThousand" /t REG_SZ /d "," /f
    reg add "HKU\DefaultUser\Control Panel\International" /v "sCurrency" /t REG_SZ /d "$" /f
    
    # Set default keyboard layout for new users
    reg add "HKU\DefaultUser\Keyboard Layout\Preload" /v "1" /t REG_SZ /d "00000c09" /f
    
    # Set default geographic location for new users
    reg add "HKU\DefaultUser\Control Panel\International\Geo" /v "Name" /t REG_SZ /d "AU" /f
    reg add "HKU\DefaultUser\Control Panel\International\Geo" /v "Nation" /t REG_SZ /d "12" /f
    
    # Unload the default user hive
    reg unload "HKU\DefaultUser"

    # System-wide registry settings
    Write-Host "Configuring system-wide registry settings..." -ForegroundColor Yellow
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language" /v "Default" /t REG_SZ /d "0c09" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language" /v "InstallLanguage" /t REG_SZ /d "0c09" /f
    
    # Set the default user locale
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Nls\Locale" /v "(Default)" /t REG_SZ /d "00000c09" /f

    # Force Windows to refresh language settings
    Write-Host "Refreshing language settings..." -ForegroundColor Yellow
    try {
        # Trigger language settings refresh
        $code = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@
        Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
        [Win32]::PostMessage([System.IntPtr]0xffff, 0x001A, [System.IntPtr]::Zero, [System.IntPtr]::Zero) | Out-Null
        Write-Host "Language refresh signal sent" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not send language refresh signal: $($_.Exception.Message)"
    }

    # Verification
    Write-Host "`nVerifying current settings..." -ForegroundColor Green
    Write-Host "System Locale: $((Get-WinSystemLocale).Name)" -ForegroundColor Cyan
    Write-Host "Culture: $((Get-Culture).Name)" -ForegroundColor Cyan
    Write-Host "Home Location: $((Get-WinHomeLocation).GeoId)" -ForegroundColor Cyan
    
    try {
        $currentUI = Get-SystemPreferredUILanguage -ErrorAction SilentlyContinue
        Write-Host "System Preferred UI Language: $currentUI" -ForegroundColor Cyan
        
        $uiOverride = Get-WinUILanguageOverride -ErrorAction SilentlyContinue
        if ($uiOverride) {
            Write-Host "UI Language Override: $uiOverride" -ForegroundColor Cyan
        }
        
        $userLangs = Get-WinUserLanguageList
        Write-Host "User Languages: $($userLangs.LanguageTag -join ', ')" -ForegroundColor Cyan
    }
    catch {
        Write-Host "UI Language: Unable to retrieve complete information" -ForegroundColor Yellow
    }

    # Create Intune detection marker
    Write-Host "`nCreating Intune detection marker..." -ForegroundColor Yellow
    try {
        $regPath = "HKLM:\Software\SOE\Lang"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "Installed" -Type String -Value "true"
        Set-ItemProperty -Path $regPath -Name "Language" -Type String -Value $LanguageSetting
        Set-ItemProperty -Path $regPath -Name "UILanguage" -Type String -Value $UILanguage
        Set-ItemProperty -Path $regPath -Name "InstallDate" -Type String -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Set-ItemProperty -Path $regPath -Name "Method" -Type String -Value "Online"
        Set-ItemProperty -Path $regPath -Name "Version" -Type String -Value "Online-Only-Fixed"
        Write-Host "Detection marker created successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not create detection marker: $($_.Exception.Message)"
    }

    Write-Host "`nConfiguration completed successfully!" -ForegroundColor Green
    
    if ($RebootRequired) {
        Write-Host "IMPORTANT: A system restart is required for all changes to take effect." -ForegroundColor Red
        Write-Host "After restart, Windows display language should be: $UILanguage" -ForegroundColor Cyan
        Write-Host "Regional settings will be: $LanguageSetting (Australian English)" -ForegroundColor Cyan
        Write-Host "New user accounts will inherit these language settings." -ForegroundColor Cyan
    }

}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    $InstallationSuccessful = $false
}
finally {
    Stop-Transcript
}

# Return appropriate exit codes for Intune
if (-not $InstallationSuccessful) {
    Write-Host "Installation failed" -ForegroundColor Red
    exit 1
}
elseif ($RebootRequired) {
    Write-Host "Installation successful - reboot required" -ForegroundColor Yellow
    exit 3010
}
else {
    Write-Host "Installation successful - no reboot required" -ForegroundColor Green
    exit 0
}
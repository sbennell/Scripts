# Requires -RunAsAdministrator
<#
    .NOTES
    ===========================================================================
    Created on:    27-8-2025
    Last Updated:  27-8-2025
    Version:       27-8-2025
    Author:        Stewart Bennell
    Filename:      install-LanguagePacks.ps1
    ===========================================================================
    .SYNOPSIS
    configures Australian English language settings using modern
    Install-Language cmdlet with comprehensive registry configuration for Intune deployment.
    
    .DESCRIPTION
    This script combines modern language pack installation via Microsoft Store
    with comprehensive registry configuration for default user profiles.
    Handles both online (Install-Language) and offline (CAB files) scenarios.
#>

param(
    [string]$LanguageSetting = "en-AU",
    [int]$GeoId = 12,
    [string]$UILanguage = "en-GB",
    [switch]$OfflineMode = $false
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
Write-Host "UI Language: $UILanguage | GeoId: $GeoId | Offline Mode: $OfflineMode" -ForegroundColor Cyan

try {
    # Import required modules
    Write-Host "Importing required modules..." -ForegroundColor Yellow
    Import-Module International -ErrorAction Stop
    
    if (-not $OfflineMode) {
        try {
            Import-Module LanguagePackManagement -ErrorAction Stop
            Write-Host "LanguagePackManagement module loaded successfully" -ForegroundColor Green
        }
        catch {
            Write-Warning "LanguagePackManagement module not available, falling back to offline mode"
            $OfflineMode = $true
        }
    }

    # Method 1: Modern Install-Language (Online)
    if (-not $OfflineMode) {
        Write-Host "Using modern Install-Language method..." -ForegroundColor Yellow
        
        # Check if language is already installed
        $Languages = Get-InstalledLanguage
        $LanguagePresent = $Languages | Where-Object { $_.LanguageId -eq $LanguageSetting -or $_.Language -eq $LanguageSetting }
        
        if (-not $LanguagePresent) {
            Write-Host "Installing language pack: $LanguageSetting" -ForegroundColor Yellow
            try {
                Install-Language -Language $LanguageSetting -CopyToSettings -ErrorAction Stop
                Write-Host "Language pack installed successfully" -ForegroundColor Green
                $RebootRequired = $true
            }
            catch {
                Write-Warning "Install-Language failed: $($_.Exception.Message)"
                Write-Host "Falling back to offline CAB installation..." -ForegroundColor Yellow
                $OfflineMode = $true
            }
        }
        else {
            Write-Host "Language pack already installed: $LanguageSetting" -ForegroundColor Cyan
        }
    }

    # Method 2: Offline CAB installation (Fallback or explicit)
    if ($OfflineMode) {
        Write-Host "Using offline CAB installation method..." -ForegroundColor Yellow
        
        $CabPath = Join-Path -Path $PSScriptRoot -ChildPath "Languagepacks"
        $CabFiles = @(
            "Microsoft-Windows-Client-Language-Pack_x64_en-gb.cab",
            "Microsoft-Windows-LanguageFeatures-Basic-en-au-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-Handwriting-en-gb-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-OCR-en-gb-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-Speech-en-au-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-TextToSpeech-en-au-Package~31bf3856ad364e35~amd64~~.cab"
        )

        if (Test-Path $CabPath) {
            foreach ($Cab in $CabFiles) {
                $FullPath = Join-Path -Path $CabPath -ChildPath $Cab

                if (-Not (Test-Path $FullPath)) {
                    Write-Warning "Skipping missing file: $FullPath"
                    continue
                }

                # Check if already installed
                $packageName = $Cab.Split('_')[0] -replace "Microsoft-Windows-", ""
                $alreadyInstalled = Get-WindowsPackage -Online | Where-Object { $_.PackageName -like "*$packageName*" -and $_.State -eq "Installed" }
                
                if ($alreadyInstalled) {
                    Write-Host "Skipping $Cab (already installed)" -ForegroundColor Cyan
                    continue
                }

                Write-Host "Installing $Cab..." -ForegroundColor Yellow
                $proc = Start-Process -FilePath dism.exe -ArgumentList "/Online","/Add-Package","/PackagePath:$FullPath","/Quiet","/NoRestart" -Wait -PassThru

                if ($proc.ExitCode -ne 0) {
                    Write-Error "DISM failed to install $Cab (Exit Code: $($proc.ExitCode))"
                    $InstallationSuccessful = $false
                } else {
                    Write-Host "$Cab installed successfully" -ForegroundColor Green
                    $RebootRequired = $true
                }
            }
        }
        else {
            Write-Warning "CAB files directory not found: $CabPath"
            Write-Warning "Cannot proceed with offline installation"
        }
    }

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

    # User Language List
    $currentLanguages = Get-WinUserLanguageList
    if ($currentLanguages[0].LanguageTag -ne $LanguageSetting) {
        Write-Host "Setting user language list to: $LanguageSetting" -ForegroundColor Yellow
        Set-WinUserLanguageList $LanguageSetting -Force
        $RebootRequired = $true
    }

    # UI Language
    try {
        $currentUILang = Get-SystemPreferredUILanguage
        if ($currentUILang -ne $UILanguage) {
            Write-Host "Setting system preferred UI language to: $UILanguage" -ForegroundColor Yellow
            Set-SystemPreferredUILanguage -Language $UILanguage
            $RebootRequired = $true
        }
    }
    catch {
        Write-Warning "Could not set UI language: $($_.Exception.Message)"
    }

    # Set timezone
    Write-Host "Setting timezone to Australian Eastern Standard Time..." -ForegroundColor Yellow
    & tzutil /s "AUS Eastern Standard Time"

    # UI Language Override
    try {
        Write-Host "Setting UI language override to: $LanguageSetting" -ForegroundColor Yellow
        Set-WinUILanguageOverride -Language $LanguageSetting
    }
    catch {
        Write-Warning "Could not set UI language override: $($_.Exception.Message)"
    }

    # Culture opt-out
    Write-Host "Configuring culture-based language list opt-out..." -ForegroundColor Yellow
    Set-WinCultureFromLanguageListOptOut -OptOut $true

    # Configure default profile for new users
    Write-Host "`nConfiguring default user profile..." -ForegroundColor Green
    
    try {
        $defaultUserPath = "C:\Users\Default\NTUSER.DAT"
        if (Test-Path $defaultUserPath) {
            & reg load "HKU\DefaultUser" $defaultUserPath

            $regSettings = @{
                "LocaleName" = $LanguageSetting
                "sCountry" = "Australia"
                "sLanguage" = "ENA"
                "sLongDate" = "d MMMM yyyy"
                "sShortDate" = "d/MM/yyyy"
                "sTimeFormat" = "h:mm:ss tt"
                "iCountry" = "61"
                "sDecimal" = "."
                "sThousand" = ","
                "sCurrency" = "$"
            }

            foreach ($setting in $regSettings.GetEnumerator()) {
                & reg add "HKU\DefaultUser\Control Panel\International" /v $setting.Key /t REG_SZ /d $setting.Value /f | Out-Null
            }

            # Keyboard layout
            & reg add "HKU\DefaultUser\Keyboard Layout\Preload" /v "1" /t REG_SZ /d "00000c09" /f | Out-Null

            # Geographic settings
            & reg add "HKU\DefaultUser\Control Panel\International\Geo" /v "Name" /t REG_SZ /d "AU" /f | Out-Null
            & reg add "HKU\DefaultUser\Control Panel\International\Geo" /v "Nation" /t REG_SZ /d "12" /f | Out-Null

            & reg unload "HKU\DefaultUser"
            Write-Host "Default user profile configured successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Could not configure default user profile: $($_.Exception.Message)"
    }

    # System-wide registry settings
    Write-Host "Configuring system-wide registry settings..." -ForegroundColor Yellow
    try {
        & reg add "HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language" /v "Default" /t REG_SZ /d "0c09" /f | Out-Null
        & reg add "HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language" /v "InstallLanguage" /t REG_SZ /d "0c09" /f | Out-Null
        & reg add "HKLM\SYSTEM\CurrentControlSet\Control\Nls\Locale" /ve /t REG_SZ /d "00000c09" /f | Out-Null
        Write-Host "System registry settings configured" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not configure system registry: $($_.Exception.Message)"
    }

    # Verification
    Write-Host "`nVerifying current settings..." -ForegroundColor Green
    Write-Host "System Locale: $((Get-WinSystemLocale).Name)" -ForegroundColor Cyan
    Write-Host "Culture: $((Get-Culture).Name)" -ForegroundColor Cyan
    Write-Host "Home Location: $((Get-WinHomeLocation).GeoId)" -ForegroundColor Cyan
    
    try {
        Write-Host "UI Language: $(Get-SystemPreferredUILanguage)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "UI Language: Unable to retrieve" -ForegroundColor Yellow
    }

    # Create Intune detection marker
    Write-Host "`nCreating Intune detection marker..." -ForegroundColor Yellow
    New-Item -Path "HKLM:\Software\SOE\Lang" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\SOE\Lang" -Name "Installed" -Type String -Value "true"
    Set-ItemProperty -Path "HKLM:\Software\SOE\Lang" -Name "Language" -Type String -Value $LanguageSetting
    Set-ItemProperty -Path "HKLM:\Software\SOE\Lang" -Name "InstallDate" -Type String -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Set-ItemProperty -Path "HKLM:\Software\SOE\Lang" -Name "Method" -Type String -Value $(if($OfflineMode) { "CAB" } else { "Online" })

    Write-Host "`nConfiguration completed successfully!" -ForegroundColor Green
    
    if ($RebootRequired) {
        Write-Host "IMPORTANT: A system restart is required for all changes to take effect." -ForegroundColor Red
        Write-Host "New user accounts created after restart will default to Australian English (en-AU)." -ForegroundColor Cyan
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

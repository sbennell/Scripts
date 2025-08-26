# Detection script for Intune Win32 app deployment
<#
    .NOTES
    ===========================================================================
    Created on:    27-8-2025
    Author:        Stewart Bennell
    Filename:      detect-LanguagePacks.ps1
    ===========================================================================
    .SYNOPSIS
    Detection script to verify Australian English language pack installation
    and configuration for Intune deployment.
#>

param(
    [string]$LanguageSetting = "en-AU",
    [int]$GeoId = 12
)

# Setup detection logging
$logDir = [IO.Path]::Combine($env:ProgramData, "Scripts", "LanguageSetup")
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logPath = Join-Path $logDir "DetectionLog.txt"
Start-Transcript -Path $logPath -Force -IncludeInvocationHeader

Write-Host "Starting language pack detection for: $LanguageSetting" -ForegroundColor Cyan

try {
    # Import required modules
    Import-Module International -ErrorAction Stop
    
    # Check Intune marker registry key first
    Write-Host "Checking Intune installation marker..." -ForegroundColor Yellow
    $markerPath = "HKLM:\Software\SOE\Lang"
    
    if (Test-Path $markerPath) {
        $installed = Get-ItemProperty -Path $markerPath -Name "Installed" -ErrorAction SilentlyContinue
        $installedLanguage = Get-ItemProperty -Path $markerPath -Name "Language" -ErrorAction SilentlyContinue
        
        if ($installed.Installed -eq "true" -and $installedLanguage.Language -eq $LanguageSetting) {
            Write-Host "Installation marker found for language: $($installedLanguage.Language)" -ForegroundColor Green
        } else {
            Write-Host "Installation marker not found or language mismatch" -ForegroundColor Red
            Stop-Transcript
            exit 1
        }
    } else {
        Write-Host "Installation marker registry key not found" -ForegroundColor Red
        Stop-Transcript
        exit 1
    }

    # Check if LanguagePackManagement module is available
    $hasLanguagePackMgmt = $false
    try {
        Import-Module LanguagePackManagement -ErrorAction Stop
        $hasLanguagePackMgmt = $true
        Write-Host "LanguagePackManagement module available" -ForegroundColor Green
    }
    catch {
        Write-Host "LanguagePackManagement module not available - checking via alternative methods" -ForegroundColor Yellow
    }

    # Method 1: Check via LanguagePackManagement module
    if ($hasLanguagePackMgmt) {
        Write-Host "Checking installed languages via LanguagePackManagement..." -ForegroundColor Yellow
        $Languages = Get-InstalledLanguage
        $LanguagePresent = $Languages | Where-Object { $_.LanguageId -eq $LanguageSetting -or $_.Language -eq $LanguageSetting }
        
        if (-not $LanguagePresent) {
            Write-Host "$LanguageSetting language pack not found via Get-InstalledLanguage" -ForegroundColor Red
            Stop-Transcript
            exit 1
        } else {
            Write-Host "Language pack confirmed installed: $($LanguagePresent.LanguageId)" -ForegroundColor Green
        }
    }

    # Method 2: Check via Windows packages (CAB installation detection)
    Write-Host "Checking Windows packages for language features..." -ForegroundColor Yellow
    $languagePackages = Get-WindowsPackage -Online | Where-Object { 
        $_.PackageName -like "*Language*" -and 
        ($_.PackageName -like "*en-au*" -or $_.PackageName -like "*en-gb*") -and
        $_.State -eq "Installed"
    }
    
    if ($languagePackages.Count -eq 0) {
        Write-Host "No language packages found via Get-WindowsPackage" -ForegroundColor Yellow
        # Don't fail here as modern installation might not show packages this way
    } else {
        Write-Host "Found $($languagePackages.Count) installed language packages" -ForegroundColor Green
        foreach ($pkg in $languagePackages) {
            Write-Host "  - $($pkg.PackageName)" -ForegroundColor Cyan
        }
    }

    # Check System Locale
    Write-Host "Checking system locale..." -ForegroundColor Yellow
    $systemLocale = Get-WinSystemLocale
    if ($systemLocale.Name -ne $LanguageSetting) {
        Write-Host "System locale mismatch: Expected $LanguageSetting, Found $($systemLocale.Name)" -ForegroundColor Red
        Stop-Transcript
        exit 1
    } else {
        Write-Host "System locale correct: $($systemLocale.Name)" -ForegroundColor Green
    }

    # Check Culture
    Write-Host "Checking culture..." -ForegroundColor Yellow
    $culture = Get-Culture
    if ($culture.Name -ne $LanguageSetting) {
        Write-Host "Culture mismatch: Expected $LanguageSetting, Found $($culture.Name)" -ForegroundColor Red
        Stop-Transcript
        exit 1
    } else {
        Write-Host "Culture correct: $($culture.Name)" -ForegroundColor Green
    }

    # Check Home Location
    Write-Host "Checking home location..." -ForegroundColor Yellow
    $homeLocation = Get-WinHomeLocation
    if ($homeLocation.GeoId -ne $GeoId) {
        Write-Host "Home location mismatch: Expected $GeoId, Found $($homeLocation.GeoId)" -ForegroundColor Red
        Stop-Transcript
        exit 1
    } else {
        Write-Host "Home location correct: $($homeLocation.GeoId)" -ForegroundColor Green
    }

    # Check User Language List
    Write-Host "Checking user language list..." -ForegroundColor Yellow
    $userLanguages = Get-WinUserLanguageList
    $primaryLanguage = $userLanguages[0]
    if ($primaryLanguage.LanguageTag -ne $LanguageSetting) {
        Write-Host "Primary user language mismatch: Expected $LanguageSetting, Found $($primaryLanguage.LanguageTag)" -ForegroundColor Red
        Stop-Transcript
        exit 1
    } else {
        Write-Host "Primary user language correct: $($primaryLanguage.LanguageTag)" -ForegroundColor Green
    }

    # Check UI Language (if available)
    try {
        Write-Host "Checking preferred UI language..." -ForegroundColor Yellow
        $uiLanguage = Get-SystemPreferredUILanguage
        Write-Host "UI Language: $uiLanguage" -ForegroundColor Cyan
        # Note: UI language might be en-GB while system locale is en-AU - this is acceptable
    }
    catch {
        Write-Host "Cannot retrieve UI language - this is acceptable" -ForegroundColor Yellow
    }

    # Check system registry settings
    Write-Host "Checking system registry settings..." -ForegroundColor Yellow
    try {
        $regDefault = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language" -Name "Default" -ErrorAction SilentlyContinue).Default
        if ($regDefault -ne "0c09") {
            Write-Host "Registry language default mismatch: Expected 0c09, Found $regDefault" -ForegroundColor Yellow
            # Don't fail on this as it might not be critical
        } else {
            Write-Host "Registry language default correct: $regDefault" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Could not check registry language settings" -ForegroundColor Yellow
    }

    # Final verification summary
    Write-Host "`nDetection Summary:" -ForegroundColor Green
    Write-Host "✓ Installation marker present" -ForegroundColor Green
    Write-Host "✓ System locale: $($systemLocale.Name)" -ForegroundColor Green
    Write-Host "✓ Culture: $($culture.Name)" -ForegroundColor Green
    Write-Host "✓ Home location: $($homeLocation.GeoId)" -ForegroundColor Green
    Write-Host "✓ Primary user language: $($primaryLanguage.LanguageTag)" -ForegroundColor Green
    
    Write-Host "`nAll detection criteria passed!" -ForegroundColor Green

}
catch {
    Write-Error "Detection script failed: $($_.Exception.Message)"
    Stop-Transcript
    exit 1
}
finally {
    Stop-Transcript
}

# Success - package is properly installed and configured
exit 0
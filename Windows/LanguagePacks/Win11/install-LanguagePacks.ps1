# Requires -RunAsAdministrator

<#
    .NOTES
    ===========================================================================
    Created on:    4/3/2025
    Last Updated:  27/5/2025
    Version:       04.03.25-08
    Author:        Stewart Bennell (sbennell) - https://github.com/sbennell/
    Filename:      Set-SystemLanguage.ps1
    ===========================================================================
    .SYNOPSIS
    Installs Australian and British English language features, configures 
    regional settings to Australia (en-AU), downloads missing CABs from GitHub.
#>

# Ensure script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You must run this script as an Administrator!"
    exit 1
}

# Start transcript logging
$LogPath = "C:\Windows\Logs\Set-SystemLanguage.log"
if (-not (Test-Path (Split-Path $LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
}
Start-Transcript -Path $LogPath -Append -ErrorAction SilentlyContinue

try {
    # Step 1: Install .CAB language packages
    try {
        Write-Output "Installing additional language feature packages..."

        $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
        $CabPath = Join-Path -Path $ScriptPath -ChildPath "Languagepacks"
        $BaseUrl = "https://raw.githubusercontent.com/sbennell/Scripts/refs/heads/master/Windows/LanguagePacks/Win11"

        $CabFiles = @(
            "Microsoft-Windows-Client-Language-Pack_x64_en-gb.cab",
            "Microsoft-Windows-LanguageFeatures-Basic-en-au-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-Handwriting-en-gb-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-OCR-en-gb-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-Speech-en-au-Package~31bf3856ad364e35~amd64~~.cab",
            "Microsoft-Windows-LanguageFeatures-TextToSpeech-en-au-Package~31bf3856ad364e35~amd64~~.cab"
        )

        foreach ($Cab in $CabFiles) {
            # Check if CAB is already installed
            $alreadyInstalled = Get-WindowsPackage -Online |
                Where-Object { $_.PackageName -like "*$Cab*" }

            if ($alreadyInstalled) {
                Write-Output "✅ Skipping $Cab (already installed)"
                continue
            }

            $FullPath = Join-Path -Path $CabPath -ChildPath $Cab

            if (-not (Test-Path $FullPath)) {
                Write-Warning "CAB file not found locally: $Cab"
                Write-Output "Downloading from GitHub..."

                if (-not (Test-Path $CabPath)) {
                    New-Item -ItemType Directory -Path $CabPath -Force | Out-Null
                }

                $DownloadUrl = "$BaseUrl/$Cab"
                try {
                    Invoke-WebRequest -Uri $DownloadUrl -OutFile $FullPath -UseBasicParsing
                    Write-Output "Downloaded: $Cab"
                } catch {
                    Write-Error "Failed to download $Cab from $DownloadUrl. $_"
                    continue
                }
            }

            Write-Output "`nInstalling: $Cab"
            $proc = Start-Process dism -ArgumentList "/Online", "/Add-Package", "/PackagePath:$FullPath" -NoNewWindow -Wait -PassThru
            if ($proc.ExitCode -ne 0) {
                Write-Error "DISM failed to install package: $Cab (Exit Code: $($proc.ExitCode))"
                continue
            }
        }

        Write-Output "`nLanguage feature installation complete."
    } catch {
        Write-Error "An error occurred during CAB installation: $_"
        exit 1
    }

    # Step 2: Apply language and regional settings
    try {
        Write-Output "`nApplying Australian locale and language settings..."

        $LanguageList = New-WinUserLanguageList en-AU
        $LanguageList.Add("en-GB")
        Set-WinUserLanguageList $LanguageList -Force

        Set-SystemPreferredUILanguage en-AU
        Set-WinSystemLocale en-AU
        Set-WinUILanguageOverride -Language en-AU
        Set-WinHomeLocation -GeoId 12
        Set-WinCultureFromLanguageListOptout -OptOut $true

        Import-Module International -ErrorAction SilentlyContinue
        Set-Culture -CultureInfo en-AU

        $TimeZone = "AUS Eastern Standard Time"
        if ((tzutil /l) -match [regex]::Escape($TimeZone)) {
            tzutil /s "$TimeZone"
        } else {
            Write-Warning "Time zone '$TimeZone' not recognized. Skipping tzutil configuration."
        }

        Write-Output "Locale and language settings successfully applied."
    } catch {
        Write-Error "An error occurred while applying language settings: $_"
        exit 1
    }

    # Step 3: Write Intune detection registry key
    try {
        $RegPath = "HKLM:\Software\SOE\Lang"
        if (-not (Test-Path $RegPath)) {
            New-Item -Path $RegPath -Force | Out-Null
        }
        New-ItemProperty -Path $RegPath -Name "Installed" -Value "True" -PropertyType String -Force | Out-Null
        Write-Output "✅ Registry marker written to $RegPath (Installed=True)"
    } catch {
        Write-Warning "Failed to write Intune detection registry key: $_"
    }

    Write-Output "`n✅ Script completed successfully. A system restart is recommended to apply all changes."
}
finally {
    Stop-Transcript | Out-Null
}

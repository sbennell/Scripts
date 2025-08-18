
# LockScreenInfo Deployment Guide

## Overview

**LockScreenInfo** is a PowerShell-based solution that updates Windows lock screens with system information, organizational branding, and contact info.  
This guide covers:

1.  Folder structure and files
    
2.  Installation
    
3.  Detection
    
4.  Uninstallation
    
5.  Scheduled task behavior
    
6.  Logging
    
7.  Intune deployment recommendations
    
8.  Installation examples
    

----------

## 1. Folder Structure

Folder

Purpose

`C:\Windows\OEMFiles\Script\LockScreenInfo`

Main script and resources

`C:\Windows\OEMFiles\Wallpaper`

Background wallpaper images

`C:\Windows\OEMFiles\LockScreen`

Generated lock screen images

`C:\Windows\OEMFiles\logs`

Installation/uninstallation logs

> **Note:** All folders are automatically created by the install/uninstall scripts if they do not exist.

----------

## 2. Installation Script (`Install-LockScreenInfo.ps1`)

### Features

-   Copies files from source (`.\Files`) to `$Destination`
    
-   Creates necessary folder structure
    
-   Adds registry key for Intune detection (`HKLM:\Software\SOE\LockScreenInfo`)
    
-   Creates a scheduled task to update the lock screen:
    
    -   At user logon
        
    -   Weekly on Monday at 9:00 AM
        
-   Runs **initial lock screen generation** immediately after installation
    
-   Logs actions to `C:\Windows\OEMFiles\logs\LockScreenInfo_Install.log`
    
-   Supports parameters:
    
    -   `ContactInfo`
        
    -   `Organization`
        
    -   `HideOrganization` / `HideContact`
        
    -   `HTMLPath`
        
    -   `BackgroundImage`
        
    -   `TargetImage`
        
    -   `FontSizeMultiplier`
        

### Example Installation Command

``.\Install-LockScreenInfo.ps1 `
    -ContactInfo "For support, call IT" `
    -Organization "Contoso Corp" `
    -HTMLPath "format_bottom_right.html" `
    -BackgroundImage "C:\Windows\OEMFiles\Wallpaper\wallpaper.jpg"`` 

----------

## 3. Detection Script (`Detect-LockScreenInfo.ps1`)

### Purpose

-   Used by Intune to verify if `LockScreenInfo` is installed
    
-   Checks:
    
    -   Registry key `HKLM:\Software\SOE\LockScreenInfo`
        
    -   Installation folder `C:\Windows\OEMFiles\Script\LockScreenInfo`
        
    -   Installed version ≥ minimum required (`1.2.0` by default)
        

### Exit Codes

Exit Code

Meaning

0

Installed and version meets minimum requirement

1

Not installed or version too low

----------

## 4. Uninstallation Script (`Uninstall-LockScreenInfo.ps1`)

### Features

-   Removes scheduled task `LockScreenInfo`
    
-   Removes installed files in `C:\Windows\OEMFiles\Script\LockScreenInfo`
    
-   Removes registry key `HKLM:\Software\SOE\LockScreenInfo`
    
-   Logs actions to `C:\Windows\OEMFiles\logs\LockScreenInfo_Uninstall.log`
    

### Example Uninstall Command

`.\Uninstall-LockScreenInfo.ps1` 

----------

## 5. Scheduled Task Details

Property

Value

Task Name

LockScreenInfo

User

SYSTEM

Run Level

Highest privileges

Triggers

At logon, Weekly Monday 09:00 AM

Action

Runs `powershell.exe` with install parameters

> **Note:** The scheduled task ensures lock screen updates continue automatically after the initial deployment.

----------

## 6. Logging

Script

Log File Location

Install

`C:\Windows\OEMFiles\logs\LockScreenInfo_Install.log`

Uninstall

`C:\Windows\OEMFiles\logs\LockScreenInfo_Uninstall.log`

**Logging includes:**

-   Folder creation
    
-   File copy status
    
-   Registry updates
    
-   Scheduled task creation/removal
    
-   Initial lock screen generation status
    

----------

## 7. Intune Deployment Recommendations

1.  **Package Files:** Include:
    
    -   `Install-LockScreenInfo.ps1`
        
    -   `Files\` folder containing all LockScreenInfo resources
        
    -   Optionally: `Uninstall-LockScreenInfo.ps1` for Intune uninstall
        
2.  **Intune Win32 App Setup:**
    
    -   **Install command:**
        
        `powershell.exe -ExecutionPolicy Bypass -File Install-LockScreenInfo.ps1` 
        
    -   **Uninstall command:**
        
        `powershell.exe -ExecutionPolicy Bypass -File Uninstall-LockScreenInfo.ps1` 
        
    -   **Detection rule:** Use `Detect-LockScreenInfo.ps1` as a **custom detection script**
        
    -   **Return codes:** 0 = installed, 1 = not installed
        
3.  **Deployment:** Target device groups where the lock screen should be applied.
    

----------

## 8. Installation Command Examples

**Mother Teresa Catholic College:**

``powershell.exe -ExecutionPolicy Bypass -File install.ps1 `
    -HideOrganization `
    -ContactInfo "For help, email: itsupport@motherteresa.catholic.edu.au" `
    -HTMLPath "format_Bottom_Right.html" `
    -BackgroundImage "C:\Windows\OEMFiles\Wallpaper\wallpaper.jpg"`` 

**Westmeadows Primary School:**

``powershell.exe -ExecutionPolicy Bypass -File install.ps1 `
    -Organization "Westmeadows Primary School" `
    -ContactInfo "For help, helpdesk.westmeadows.vic.edu.au" `
    -HTMLPath "format_top_left.html" `
    -BackgroundImage "C:\Windows\OEMFiles\Wallpaper\wallpaper.jpg"`` 

**St Joseph the Worker Primary School:**

``powershell.exe -ExecutionPolicy Bypass -File install.ps1 `
    -HideOrganization `
    -ContactInfo "For help, email: itsupport@sjwreservoirnth.catholic.edu.au" `
    -HTMLPath "format_top_left.html" `
    -BackgroundImage "C:\Windows\OEMFiles\Wallpaper\wallpaper.jpg"`` 

**Morang South Primary School:**

``powershell.exe -ExecutionPolicy Bypass -File install.ps1 `
    -Organization "Morang South Primary School" `
    -ContactInfo "For help, helpdesk.westmeadows.vic.edu.au" `
    -HTMLPath "format_top_left.html" `
    -BackgroundImage "C:\Windows\OEMFiles\Wallpaper\wallpaper.jpg"`` 

----------

### Tips:

-   Use `-HideOrganization` **if you don’t want the organization name displayed** on the lock screen.
    
-   `-ContactInfo` should be customized for each site’s IT support email or phone.
    
-   `-HTMLPath` determines the position/layout of the information on the lock screen.
    
-   `-BackgroundImage` can point to a site-specific wallpaper if required.
    

----------

### ✅ Notes for IT Teams

-   Update `$ScriptVersion` in `Install-LockScreenInfo.ps1` for new releases.
    
-   Update `$RequiredVersion` in `Detect-LockScreenInfo.ps1` accordingly.
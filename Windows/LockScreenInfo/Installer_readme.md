# LockScreenInfo Deployment Guide

## Overview
LockScreenInfo generates custom Windows lock screen backgrounds with system information overlay using PowerShell and HTML templates.

## Features
- 4 positioning templates (corners of screen)
- Dynamic font scaling based on screen resolution  
- Customizable organization name and contact information
- Weekly scheduled updates + startup refresh
- Comprehensive logging system
- Multi-tenant support with parameterized deployment

## Intune Deployment Steps

### 1. Package Preparation
Create a folder with these files:
```
DeploymentPackage/
├── LockScreenInfo.ps1          
├── format_bottom_left.html     
├── format_Bottom_Right.html    
├── format_top_left.html        
├── format_top_right.html       
├── wkhtmltoimage.exe           
├── wkhtmltox.dll               
├── libwkhtmltox.a              
├── LICENSE                     
├── readme.md                   
├── wallpaper.jpg               
├── install.ps1                 
├── uninstall.ps1               
└── detect.ps1                  
```

### 2. Create .intunewin Package
```bash
# Use Microsoft Win32 Content Prep Tool
.\IntuneWinAppUtil.exe -c "C:\DeploymentPackage" -s "install.ps1" -o "C:\Output"
```

### 3. Intune Configuration

**App Information:**
- Name: LockScreenInfo System Information
- Description: Displays system information on Windows lock screen
- Publisher: Stewart Bennell

**Program:**
- Install command: See examples below
- Uninstall command: `powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1`
- Install behavior: System
- Device restart behavior: No specific action

**Requirements:**
- OS: Windows 10 1607+ / Windows 11
- Architecture: x64
- PowerShell 5.1+

**Detection Rules:**
- Use custom detection script
- Upload: detect.ps1
- Run as 32-bit: No

### 4. Install Command Examples

**Mother Teresa Catholic College:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1 -HideOrganization -ContactInfo "For help, email: itsupport@motherteresa.catholic.edu.au" -HTMLPath "format_Bottom_Right.html" -BackgroundImage "c:\windows\OEMFiles\Wallpaper\wallpaper.jpg"
```

**Westmeadows PS:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1 -Organization "Westmeadows Primary School" -ContactInfo "For help, helpdesk.westmeadows.vic.edu.au" -HTMLPath "format_top_left.html" -BackgroundImage "c:\windows\OEMFiles\Wallpaper\wallpaper.jpg"
```

**High Security (Minimal Info):**
```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1 -HideOrganization -HideContact -HTMLPath "format_top_right.html" -BackgroundImage "c:\windows\OEMFiles\Wallpaper\wallpaper.jpg"
```

**Healthcare with Large Text:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1 -Organization "St. Mary's Hospital" -ContactInfo "IT Support: ext.2480 (24/7)" -HTMLPath "format_bottom_left.html" -FontSizeMultiplier 1.3 -BackgroundImage "c:\windows\OEMFiles\Wallpaper\wallpaper.jpg"
```

## Parameter Reference

| Parameter | Type | Purpose | Example |
|-----------|------|---------|---------|
| `-Organization` | String | Company name to display | `"ABC Corp"` |
| `-HideOrganization` | Switch | Hide company name completely | |
| `-ContactInfo` | String | IT contact information | `"Help: x1234"` |
| `-HideContact` | Switch | Hide contact information | |
| `-HTMLPath` | String | Template file to use | `"format_top_left.html"` |
| `-BackgroundImage` | String | Background image path\filename | `"C:\Windows\OEMFiles\lockscreen\lockscreen.jpg"` |
| `-FontSizeMultiplier` | Double | Text size scaling (0.5-2.0) | `1.2` |
| `-CustomParameters` | String | Additional script parameters | `"-ExtraParam value"` |

## Template Options

| Template | Position | Best For |
|----------|----------|----------|
| `format_bottom_left.html` | Bottom Left | Standard corporate |
| `format_Bottom_Right.html` | Bottom Right | Default recommended |
| `format_top_left.html` | Top Left | High visibility |
| `format_top_right.html` | Top Right | Minimal interference |

## Scheduled Task Details

**Default Schedule:**
- At system startup (immediate system info refresh)
- Weekly on Monday at 9:00 AM (regular updates)

**Runs as:** SYSTEM account with highest privileges
**Battery:** Allowed to run on battery power
**Network:** Does not require network connection

## Post-Deployment Management

After deployment, you can use these management scripts:

**Change Template Position:**
```powershell
.\TemplateConfig.ps1 -Template "top_left" -RunNow
```

**Modify Schedule:**
```powershell
# Change to bi-weekly
.\ScheduleConfig.ps1 -Frequency BiWeekly -DayOfWeek Wednesday -Time "14:00"

# Daily updates
.\ScheduleConfig.ps1 -Frequency Daily -Time "08:00"
```

**View Logs:**
```powershell
# Recent activity
.\LogManager.ps1 -Action View

# All logs summary  
.\LogManager.ps1 -Action Summary

# Archive old logs
.\LogManager.ps1 -Action Archive
```

## Troubleshooting

**Check Installation:**
```powershell
# Verify files exist
Test-Path "C:\Windows\OEMFiles\Scripts\LockScreenInfo.ps1"

# Check scheduled task
Get-ScheduledTask -TaskName "LockScreenInfo"

# View recent logs
Get-Content "C:\Windows\OEMFiles\logs\LockScreenInfo.log" -Tail 20
```

**Manual Execution:**
```powershell
# Test the script manually
cd "C:\Windows\OEMFiles\Scripts"
.\LockScreenInfo.ps1 -ContactInfo "Test" -HTMLPath "format_Bottom_Right.html"
```

**Common Issues:**
1. **wkhtmltoimage.exe not found** - Ensure all files are copied during installation
2. **Permission denied** - Script must run as Administrator/SYSTEM
3. **HTML template not found** - Check HTMLPath parameter matches actual filename
4. **Background image missing** - Verify BackgroundImage exists in package

## File Locations

- **Scripts:** `C:\Windows\OEMFiles\Scripts\`
- **Logs:** `C:\Windows\OEMFiles\logs\`
- **Background:** `C:\Windows\OEMFiles\Wallpaper\`
- **Generated Image:** `C:\Windows\OEMFiles\lockscreen\lockscreen.jpg`

## Multi-Organization Deployment

For multiple organizations:
1. Create separate Win32 apps for each organization
2. Include organization-specific background images
3. Use different install command parameters
4. Target appropriate device groups
5. Name apps descriptively (e.g., "LockScreenInfo - Company A")

This allows centralized management while supporting different branding and contact information per organization.
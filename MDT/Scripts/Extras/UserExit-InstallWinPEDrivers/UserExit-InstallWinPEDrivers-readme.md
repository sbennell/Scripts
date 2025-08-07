
# UserExit-InstallWinPEDrivers.ps1

## Overview
PowerShell script for Microsoft Deployment Toolkit (MDT) that automatically installs hardware-specific drivers into the Windows PE environment during deployment. The script detects the computer make and model, then installs appropriate drivers from a structured driver repository using multiple installation methods for maximum compatibility.

## Version
- **Current Version**: 2025.08.07-11 (Fixed DISM Commands)
- **Author**: Stewart Bennell
- **License**: Copyright (c) Stewart Bennell. All rights reserved.

## Recent Updates (v2025.08.07-11)
- ✅ **Fixed DISM Commands**: Resolved error 0x80310000 by using proper WinPE installation methods
- ✅ **Multiple Installation Methods**: PnPUtil (preferred), DISM online, and legacy fallback methods
- ✅ **Enhanced Validation**: Comprehensive hardware detection and driver verification
- ✅ **Improved Error Handling**: Better logging and graceful fallback between installation methods
- ✅ **USB Deployment Support**: Optimized for USB-based WinPE deployments
- ✅ **Performance Improvements**: Reduced duplicate processing and added installation delays

## Purpose
- Installs drivers from "Drivers\WinPE" into the running Windows PE environment
- Provides hardware-specific driver installation based on computer make/model detection
- Falls back to generic drivers when specific hardware isn't recognized
- Uses multiple driver installation methods for maximum compatibility
- Comprehensive logging for troubleshooting deployment issues

## Requirements

### System Requirements
- Windows PE environment (WinPE 10.0 or later recommended)
- Microsoft Deployment Toolkit (MDT) or System Center Configuration Manager (SCCM)
- PowerShell execution in WinPE
- Administrative privileges
- PnPUtil.exe (included in WinPE)

### Driver Repository Structure
```
Drivers\WinPE\
├── Dell\
│   ├── OptiPlex 7090\
│   │   ├── Network\
│   │   ├── Storage\
│   │   └── Chipset\
│   └── Latitude 5520\
├── HP\
│   ├── EliteBook 840\
│   └── ProBook 650\
├── Lenovo\
│   ├── ThinkPad L13\       
│   ├── ThinkPad T14 Gen 3\
│   └── ThinkPad X1 Carbon\
├── All\              # Generic drivers for all systems
├── Generic\          # Universal drivers
├── Common\           # Common hardware drivers
└── Universal\        # Microsoft universal drivers
```

## Features

### Core Functionality
- **Environment Detection**: Validates Windows PE environment before execution
- **Hardware Detection**: Identifies computer make and model using WMI/CIM
- **Special Lenovo Support**: Uses `Win32_ComputerSystemProduct.Version` for accurate Lenovo model detection
- **Flexible Driver Location**: Supports both network (MDT) and local (USB) driver repositories
- **Intelligent Driver Matching**: Multiple fallback strategies for driver location
- **Comprehensive Logging**: Detailed logging with timestamps and severity levels

### Driver Installation Methods (New in v2025.08.07-11)
The script uses multiple installation methods in order of preference:

1. **PnPUtil (Preferred)**: `pnputil.exe /add-driver /install`
   - Modern, reliable method for WinPE
   - Best compatibility with current Windows versions
   - Automatic device enumeration

2. **DISM Online**: `dism.exe /online /add-driver`
   - Proper DISM syntax for running WinPE environment
   - Fixes the previous `/image:C:\` error
   - Force unsigned driver installation supported

3. **Legacy Method**: `rundll32.exe setupapi,InstallHinfSection`
   - Fallback for older or problematic drivers
   - Compatible with legacy hardware

### Driver Installation Strategies
1. **Exact Match**: `Make\Model` folder structure
2. **Partial Match**: Wildcard matching for similar model names  
3. **Generic Fallback**: Universal drivers when specific hardware isn't found
4. **Multiple Locations**: Network share or local USB drive support

### Enhanced Validation & Hardware Detection
- **Driver Installation Verification**: Uses PnPUtil to confirm successful installations
- **Storage Controller Detection**: Validates storage hardware recognition
- **Disk Drive Enumeration**: Confirms disk access for deployment
- **Network Adapter Detection**: Checks for network hardware (USB deployments show "normal" status)

### Error Handling
- Graceful fallback when Task Sequence environment unavailable
- Continues execution even if individual drivers fail
- Multiple installation method attempts per driver
- Detailed error logging for troubleshooting
- Proper exit codes for automation

## Installation & Usage

### 1. Setup Driver Repository
Create the driver folder structure in your MDT deployment share:
```
\\DeploymentServer\DeploymentShare$\Drivers\WinPE\
```

Or for USB deployments:
```
D:\Drivers\WinPE\
```

### 2. Organize Drivers by Hardware
- Create folders using manufacturer names (Dell, HP, Lenovo, etc.)
- Create subfolders using clean model names (no special characters)
- Place .inf files and associated driver files in appropriate folders
- Test with known hardware (script tested successfully with LENOVO ThinkPad L13)

### 3. Deploy Script
Place the script in your MDT Scripts folder or USB drive:
```
\\DeploymentServer\DeploymentShare$\Scripts\Extras\UserExit-InstallWinPEDrivers\UserExit-InstallWinPEDrivers.ps1
```

### 4. Task Sequence Integration (Recommended Method)
Use "Run PowerShell Script" step in your MDT task sequence:
- **PowerShell script**: `UserExit-InstallWinPEDrivers.ps1`
- **PowerShell parameters**: (leave blank)
- **Run this step**: Early in WinPE phase, before imaging operations
- **Continue on error**: Optional (script provides detailed logging)

### 5. Alternative: MDT UserExit Method
For traditional UserExit integration, add to CustomSettings.ini:

```ini
[Settings]
Priority=LoadWinPEDrivers, Default
Properties=MyCustomProperty

[LoadWinPEDrivers]
UserExit=Extras\UserExit-InstallWinPEDrivers\UserExit-InstallWinPEDrivers.vbs
```

Create VBScript wrapper `UserExit-InstallWinPEDrivers.vbs`:
```vbs
Function UserExit(sType, sWhen, sDetail, bSkip)
    Dim shell, command, exitCode, objFSO, drive
    Dim strFile, strScriptFile
    Const Success = 0

    ' Create required objects
    Set shell = CreateObject("WScript.Shell")
    Set objFSO = CreateObject("Scripting.FileSystemObject")

    ' Loop through all drives to find the PowerShell script
    For Each drive In objFSO.Drives
        If drive.IsReady Then
            strFile = drive.DriveLetter & ":\Deploy\Scripts\Extras\UserExit-InstallWinPEDrivers\UserExit-InstallWinPEDrivers.ps1"
            If objFSO.FileExists(strFile) Then
                strScriptFile = strFile
                Exit For
            End If
        End If
    Next

    ' Handle case where script was not found
    If strScriptFile = "" Then
        WScript.Quit 1
    End If

    ' Build PowerShell command
    command = "powershell.exe -ExecutionPolicy Bypass -File """ & strScriptFile & """ -Verbose"

    ' Run PowerShell script
    exitCode = shell.Run(command, 0, True)

    ' Clean up
    Set shell = Nothing
    Set objFSO = Nothing

    UserExit = Success
End Function

```

### 6. USB Deployment Support  
For USB-based deployments:
- Ensure driver structure exists on USB drive: `D:\Drivers\WinPE\`
- Script automatically detects and uses local drivers

## Configuration

### Logging Configuration
Logs are automatically created in:
- **Logging**: `X:\MININT\SMSOSD\OSDLOGS\`
- **USB/Local**: First available drive `\MININT\SMSOSD\OSDLOGS\`

Log filename format: `UserExit-InstallWinPEDrivers_YYYYMMDD_HHMMSS.log`

### Sample Successful Log Output
```
[2025-07-21 11:42:42] [INFO] Found exact match path: D:\Drivers\WinPE\LENOVO\ThinkPad L13
[2025-07-21 11:42:42] [INFO] Found 8 driver files in: D:\Drivers\WinPE\LENOVO\ThinkPad L13
[2025-07-21 11:42:42] [INFO] Successfully installed with PnPUtil: HdBusExt.inf
[2025-07-21 11:42:48] [INFO] Driver installation completed. Success: 8/8
[2025-07-21 11:42:49] [INFO] Storage controllers detected: 2
[2025-07-21 11:42:49] [INFO] Disk drives detected: 2
```

### Driver Folder Naming Conventions
- Remove special characters from folder names: `()[]{}-.,:;`
- Use spaces for readability: `ThinkPad L13`, `OptiPlex 7090`
- Manufacturer folders should match WMI output: `LENOVO`, `Dell Inc.`, `HP`
- Test folder names with actual hardware detection

## Troubleshooting

### Common Issues & Solutions

#### Script Not Running
- **Cause**: PowerShell execution policy or permissions
- **Solution**: Ensure PowerShell scripts are allowed in WinPE boot image
- **Verification**: Check for script execution in logs

#### No Drivers Found
- **Cause**: Incorrect folder structure or naming
- **Solution**: Check folder names match detected make/model in logs
- **Debug**: Enable debug logging to see path resolution

#### Network Path Unavailable  
- **Cause**: Network connectivity issues in WinPE
- **Solution**: Use USB deployment method or ensure network drivers in boot image
- **USB Alternative**: Script automatically falls back to local drive detection

#### Partial Driver Installation
- **Cause**: Some drivers incompatible with WinPE or hardware
- **Expected**: Normal behavior - script continues with compatible drivers
- **Verification**: Check success count in logs (e.g., "Success: 6/8")

### USB Deployment Notes
For USB-based deployments, these are **normal and expected**:
- "No network adapters detected (normal for USB-based WinPE deployment)"
- Script runs offline using drivers from USB drive
- Storage and disk detection should work properly

### Log Analysis Examples

**Successful Installation:**
```
[INFO] Successfully installed with PnPUtil: driver.inf
[INFO] Driver installation completed. Success: 8/8
[INFO] Script completed successfully
```

**Partial Success (Normal):**
```
[WARN] Failed to install problematic.inf: [method details]
[INFO] Successfully installed with PnPUtil: working.inf
[INFO] Driver installation completed. Success: 7/8
```

**Hardware Detection:**
```
[INFO] Computer Make: LENOVO
[INFO] Computer Model: ThinkPad L13
[INFO] Found exact match path: D:\Drivers\WinPE\LENOVO\ThinkPad L13
```

## Exit Codes
- **0**: Success - All operations completed successfully
- **1**: Error - Critical failure (not in WinPE, no drivers path, no drivers installed)

## Performance & Best Practices

### Driver Management
- Test drivers in WinPE environment before deployment
- Keep generic/universal drivers as fallback
- Regularly update drivers for new hardware models
- Use manufacturer driver packs when available
- Organize by exact model names for best matching

### Deployment Optimization
- Run early in task sequence after basic hardware initialization
- Monitor logs for successful driver installation patterns
- Use USB deployment for offline scenarios
- Test with various hardware models before production use
- Include storage and network drivers as priority

### Folder Organization Best Practices
- Use consistent naming conventions across all manufacturers
- Group similar models in manufacturer folders
- Maintain separate WinPE and full Windows driver repositories
- Document driver versions and update dates
- Test folder structure with actual hardware detection

## Support & Development
For issues or questions regarding this script:
- Review log files for detailed error information and success patterns
- Verify driver repository structure and permissions
- Test script manually in WinPE environment with known hardware
- Check MDT/SCCM documentation for PowerShell script requirements
- Consider USB deployment method for offline scenarios

## Version History
- **2025.08.07-11**: Fixed DISM commands, multiple installation methods, enhanced validation
- **2025.8.5-10**: Initial PowerShell version with comprehensive logging and error handling
- **2025.07.29-6**: Previous version


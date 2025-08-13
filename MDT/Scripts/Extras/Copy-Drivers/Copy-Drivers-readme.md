# Copy-Drivers.ps1

## Overview

The Copy-Drivers.ps1 script is a Microsoft Deployment Toolkit (MDT) PowerShell script designed to automatically install and copy appropriate drivers to the OS drive during Windows PE deployment. The script intelligently searches for model-specific drivers and falls back to generic drivers when needed.

## Purpose

- Automatically detects computer make and model during deployment
- Searches for appropriate drivers in a structured folder hierarchy
- Copies drivers to the target OS drive for later installation
- Provides comprehensive logging for troubleshooting
- Supports both folder-based and ZIP-based driver packages

## Version Information

- **Current Version**: 2025.08.07-11 (Fixed DISM Commands)
- **Author**: Stewart Bennell

## Requirements

### Environment
- Microsoft Deployment Toolkit (MDT) environment
- Windows PE deployment phase
- PowerShell execution capability
- Access to driver repository (network share or local storage)

### Task Sequence Variables
The script requires the following MDT task sequence variables:
- `OS` - Target operating system identifier
- `DeployRoot` - Path to deployment share
- `OSDisk` - Target OS drive letter
- `OSDComputerName` - Computer name for logging (optional)

## Driver Repository Structure

The script expects drivers to be organized in the following hierarchy:

```
Drivers\
├── [OS]\                    # e.g., "Windows 11", "Windows 10"
│   ├── [MAKE]\              # e.g., "DELL", "HP", "LENOVO"
│   │   ├── [MODEL]\         # Specific model folder
│   │   │   └── [driver files and folders]
│   │   └── [MODEL].zip      # Compressed model drivers
│   ├── Generic\             # Generic drivers for the OS
│   │   └── [driver files and folders]
│   └── GenericDrivers.zip   # Compressed generic drivers
```

### Examples
```
Drivers\
├── Windows 11\
│   ├── DELL\
│   │   ├── OptiPlex 7090\
│   │   ├── Latitude 5520\
│   │   └── Precision 5560.zip
│   ├── HP\
│   │   ├── EliteBook 840 G8\
│   │   └── ProDesk 600 G6.zip
│   ├── Generic\
│   └── GenericDrivers.zip
└── Windows 10\
    ├── LENOVO\
    │   ├── ThinkPad X1 Carbon\
    │   └── ThinkCentre M720q.zip
    └── Generic\
```

## Driver Search Logic

The script uses the following search priority:

1. **Exact Model Match**: Searches for exact make/model combination
   - First checks for folder: `\OS\MAKE\MODEL\`
   - Then checks for ZIP: `\OS\MAKE\MODEL.zip`

2. **Partial Model Match**: If exact match fails, searches for partial matches
   - Uses the first word of the model name for matching

3. **Generic Fallback**: If no model-specific drivers found
   - Checks for OS-specific generic folder: `\OS\Generic\`
   - Checks for OS-specific generic ZIP: `\OS\GenericDrivers.zip`

4. **Missing Model Handling**: If model information is unavailable
   - Skips model-specific search and goes directly to generic drivers

## Special Manufacturer Handling

### Lenovo
The script includes special handling for Lenovo computers, using the `Win32_ComputerSystemProduct.Version` property for more accurate model identification instead of the standard `Win32_ComputerSystem.Model`.

## Logging

### Log Locations
The script creates detailed logs in the following priority order:

1. **Network Logging** (preferred): `[DeployShare]\Logs\[ComputerName]\`
2. **Standard PE Logging**: `[Drive]\MININT\SMSOSD\OSDLOGS\`
3. **Fallback Logging**: `C:\MININT\SMSOSD\OSDLOGS\`

### Log File Format
- **File Name**: `Copy-Drivers.ps1_YYYYMMDD_HHMMSS.log`
- **Format**: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`
- **Levels**: INFO, WARN, ERROR

### Log Information Includes
- Computer make and model detection
- Driver search progress and results
- File operation status
- Error details and troubleshooting information

## Command Line Parameters Explained

The MDT command line uses several components:

- **`%ToolRoot%\ServiceUI.exe`** - MDT's ServiceUI utility for running applications in the user context during WinPE
- **`%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe`** - Full path to PowerShell executable
- **`-NoProfile`** - Skips loading PowerShell profiles for faster execution
- **`-WindowStyle Hidden`** - Runs PowerShell window hidden from user
- **`-ExecutionPolicy Bypass`** - Bypasses PowerShell execution policy restrictions
- **`-File %SCRIPTROOT%\Extras\Copy-Drivers\Copy-Drivers.ps1`** - Specifies the script file to execute

## MDT Environment Variables Used

- **`%ToolRoot%`** - Path to MDT tools directory
- **`%SYSTEMROOT%`** - Windows system root directory (usually C:\Windows)
- **`%SCRIPTROOT%`** - Path to MDT Scripts directory

### 1. Deploy the Script
Place `Copy-Drivers.ps1` in your MDT deployment share at:
```
[DeploymentShare]\Scripts\Extras\Copy-Drivers\Copy-Drivers.ps1
```

### 2. Configure Driver Repository
Organize your drivers according to the folder structure outlined above.

### 3. Add to Task Sequence
Add a "Run Command Line" step to your MDT task sequence with the following configuration:

**Command Line:**
```
%ToolRoot%\ServiceUI.exe %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File %SCRIPTROOT%\Extras\Copy-Drivers\Copy-Drivers.ps1
```

**Step Configuration:**
- **Name**: Copy Drivers to OS
- **Type**: Run Command Line  
- **Position**: During Windows PE phase, before OS installation
- **Conditions**: (optional) Add conditions based on hardware or deployment requirements

### 4. Task Sequence Variables
Ensure the following variables are set in your task sequence:
- OS (automatically set by MDT)
- DeployRoot (automatically set by MDT)
- OSDisk (automatically set by MDT)
- OSDComputerName (automatically set by MDT)

## Output

### Success
- Drivers are extracted/copied to: `[OSDrive]\Drivers\Custom\`
- Comprehensive logging of all operations
- Exit code: 0

### Failure Scenarios
- No drivers found for the system
- Unable to access driver repository
- Extraction/copy operations fail
- Exit code: 1

## Troubleshooting

### Common Issues

1. **"Base drivers folder not found"**
   - Verify network connectivity to deployment share
   - Check if drivers folder exists in expected location
   - Ensure script has access to USB/local drives as fallback

2. **"No drivers found for: [Make] [Model]"**
   - Verify driver folder structure matches expected hierarchy
   - Check if make/model names match folder names exactly
   - Consider using generic drivers as fallback

3. **"Could not determine computer make/model"**
   - WMI issues in Windows PE environment
   - Script will attempt to use generic drivers
   - Manual model specification may be needed

4. **Extraction/Copy failures**
   - Insufficient disk space on target drive
   - Corrupted ZIP files
   - Permission issues

### Debugging Steps

1. Check the detailed log file for specific error messages
2. Verify task sequence variables are properly set
3. Test driver repository access manually
4. Validate driver package integrity
5. Check available disk space on target drive

## Best Practices

1. **Driver Organization**
   - Use consistent naming conventions for makes and models
   - Test driver packages before deployment
   - Keep both specific and generic driver sets

2. **Testing**
   - Test script with various hardware models
   - Verify fallback mechanisms work correctly
   - Monitor log files during testing

3. **Maintenance**
   - Regularly update driver packages
   - Clean up old/unused driver versions
   - Monitor log files for recurring issues

## Support and Updates

For issues or improvements, review the script logs and validate the driver repository structure. The script includes comprehensive error handling and logging to assist with troubleshooting deployment issues.
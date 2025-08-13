# MDT Driver Management Scripts - Unified Documentation

## Table of Contents
1. [Copy-Drivers.ps1](#copy-driversps1)
2. [Export-Drivers.ps1](#export-driversps1)
3. [UserExit-InstallWinPEDrivers.ps1](#userexitinstallwinpedriversps1)

---

## Copy-Drivers.ps1

### Overview
Microsoft Deployment Toolkit (MDT) PowerShell script designed to automatically install and copy appropriate drivers to the OS drive during Windows PE deployment. The script intelligently searches for model-specific drivers and falls back to generic drivers when needed.

### Version Information
- **Current Version**: 2025.08.07-11 (Fixed DISM Commands)
- **Author**: Stewart Bennell
- **License**: Copyright (c) Stewart Bennell. All rights reserved.

### Purpose
- Automatically detects computer make and model during deployment
- Searches for appropriate drivers in a structured folder hierarchy
- Copies drivers to the target OS drive for later installation
- Provides comprehensive logging for troubleshooting
- Supports both folder-based and ZIP-based driver packages

### Requirements

#### Environment
- Microsoft Deployment Toolkit (MDT) environment
- Windows PE deployment phase
- PowerShell execution capability
- Access to driver repository (network share or local storage)

#### Task Sequence Variables
The script requires the following MDT task sequence variables:
- `OS` - Target operating system identifier
- `DeployRoot` - Path to deployment share
- `OSDisk` - Target OS drive letter
- `OSDComputerName` - Computer name for logging (optional)

### Driver Repository Structure
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

#### Examples
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

### Key Features

#### Driver Search Logic
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

#### Special Manufacturer Handling
**Lenovo**: The script includes special handling for Lenovo computers, using the `Win32_ComputerSystemProduct.Version` property for more accurate model identification instead of the standard `Win32_ComputerSystem.Model`.

### Installation & Usage

#### 1. Deploy the Script
Place `Copy-Drivers.ps1` in your MDT deployment share at:
```
[DeploymentShare]\Scripts\Extras\Copy-Drivers\Copy-Drivers.ps1
```

#### 2. Configure Driver Repository
Organize your drivers according to the folder structure outlined above.

#### 3. Add to Task Sequence
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

#### 4. Task Sequence Variables
Ensure the following variables are set in your task sequence:
- OS (automatically set by MDT)
- DeployRoot (automatically set by MDT)
- OSDisk (automatically set by MDT)
- OSDComputerName (automatically set by MDT)

### Command Line Parameters Explained
The MDT command line uses several components:

- **`%ToolRoot%\ServiceUI.exe`** - MDT's ServiceUI utility for running applications in the user context during WinPE
- **`%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe`** - Full path to PowerShell executable
- **`-NoProfile`** - Skips loading PowerShell profiles for faster execution
- **`-WindowStyle Hidden`** - Runs PowerShell window hidden from user
- **`-ExecutionPolicy Bypass`** - Bypasses PowerShell execution policy restrictions
- **`-File %SCRIPTROOT%\Extras\Copy-Drivers\Copy-Drivers.ps1`** - Specifies the script file to execute

### Logging

#### Log Locations
The script creates detailed logs in the following priority order:

1. **Network Logging** (preferred): `[DeployShare]\Logs\[ComputerName]\`
2. **Standard PE Logging**: `[Drive]\MININT\SMSOSD\OSDLOGS\`
3. **Fallback Logging**: `C:\MININT\SMSOSD\OSDLOGS\`

#### Log File Format
- **File Name**: `Copy-Drivers.ps1_YYYYMMDD_HHMMSS.log`
- **Format**: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`
- **Levels**: INFO, WARN, ERROR

#### Log Information Includes
- Computer make and model detection
- Driver search progress and results
- File operation status
- Error details and troubleshooting information

### Output

#### Success
- Drivers are extracted/copied to: `[OSDrive]\Drivers\Custom\`
- Comprehensive logging of all operations
- Exit code: 0

#### Failure Scenarios
- No drivers found for the system
- Unable to access driver repository
- Extraction/copy operations fail
- Exit code: 1

### Troubleshooting

#### Common Issues

**"Base drivers folder not found"**
- Verify network connectivity to deployment share
- Check if drivers folder exists in expected location
- Ensure script has access to USB/local drives as fallback

**"No drivers found for: [Make] [Model]"**
- Verify driver folder structure matches expected hierarchy
- Check if make/model names match folder names exactly
- Consider using generic drivers as fallback

**"Could not determine computer make/model"**
- WMI issues in Windows PE environment
- Script will attempt to use generic drivers
- Manual model specification may be needed

**Extraction/Copy failures**
- Insufficient disk space on target drive
- Corrupted ZIP files
- Permission issues

#### Debugging Steps
1. Check the detailed log file for specific error messages
2. Verify task sequence variables are properly set
3. Test driver repository access manually
4. Validate driver package integrity
5. Check available disk space on target drive

### Best Practices

#### Driver Organization
- Use consistent naming conventions for makes and models
- Test driver packages before deployment
- Keep both specific and generic driver sets

#### Testing
- Test script with various hardware models
- Verify fallback mechanisms work correctly
- Monitor log files during testing

#### Maintenance
- Regularly update driver packages
- Clean up old/unused driver versions
- Monitor log files for recurring issues

---

## Export-Drivers.ps1

### Overview
PowerShell script for exporting and organizing system drivers from a reference computer into the Microsoft Deployment Toolkit (MDT) drivers folder structure. This script captures all necessary drivers for deployment to similar hardware.

### Version Information
- **Current Version**: 2025.08.13-4
- **Author**: Stewart Bennell
- **License**: Copyright (c) Stewart Bennell. All rights reserved.

### Purpose
Export drivers from the current system and organize them in the DeployShare drivers folder structure for use with MDT deployments. This script is designed to be run on a fully configured reference system to capture all necessary drivers for deployment to similar hardware.

### Key Features

#### Driver Export
- Exports all installed system drivers using `Export-WindowsDriver` cmdlet
- DISM fallback method for compatibility
- Automatic exclusion of printer drivers
- Comprehensive validation of export results

#### Intelligent Path Detection
- **Network Deployment:** Uses task sequence `DeployRoot` for network-based deployments
- **USB Detection:** Automatically detects USB media via `media.tag` in `Deploy\Scripts\` folder
- **Smart Selection:** Prioritizes USB storage when running from USB media

#### Driver Organization
- Organizes drivers by device class (Audio, Display, Network, etc.)
- Sub-organizes by provider/manufacturer
- Sanitizes folder names for filesystem compatibility
- Creates clean, browsable folder structure

#### Robust Logging
- Computer-specific log folders when available
- Timestamped entries with multiple log levels (INFO, WARN, ERROR)
- Detailed operation tracking and error reporting
- Comprehensive validation results

### Folder Structure Created
```
[DeployShare]\Drivers\[OS]\[MAKE]\[MODEL]\
├── Audio\
│   ├── Realtek\
│   └── Microsoft\
├── Display\
│   ├── Intel\
│   └── NVIDIA\
├── Network\
│   ├── Intel\
│   └── Broadcom\
├── System\
│   └── [Manufacturer]\
└── USB\
    └── Microsoft\
```

### Requirements

#### Prerequisites
- Run on a fully configured reference system
- All necessary drivers installed and working
- MDT task sequence environment available
- Appropriate permissions to deployment share

#### Required Task Sequence Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `DeployRoot` | Path to deployment share | `\\server\DeployShare` or `E:\Deploy` |
| `OSDComputerName` | Computer name for logging | `REF-COMPUTER-01` |

*Note: Script will work without `OSDComputerName` but will use generic log folder*

### Deployment Scenarios

#### Network Deployment
When running from network deployment share:
- Uses `DeployRoot` from task sequence
- Saves to: `\\server\DeployShare\Drivers\[OS]\[MAKE]\[MODEL]\`
- Logs to: `\\server\DeployShare\Logs\[ComputerName]\`

#### USB Deployment
When running from USB media (detected via `media.tag`):
- Uses local USB path: `[USB]:\Deploy\Drivers\[OS]\[MAKE]\[MODEL]\`
- Logs to: `[USB]:\Deploy\Logs\[ComputerName]\`
- Enables offline driver capture scenarios

### Installation & Usage

#### Execution
```powershell
# Run from MDT task sequence
.\Export-Drivers.ps1

# Or run directly in PowerShell (with MDT environment)
.\Export-Drivers.ps1
```

#### Task Sequence Integration
1. Add "Run PowerShell Script" step in MDT task sequence
2. Script Path: `Scripts\Export-Drivers.ps1`
3. PowerShell execution policy: `Bypass`
4. Place after all drivers are installed and system is fully configured

### Hardware Detection

#### Standard Detection
- Make: Retrieved from `Win32_ComputerSystem.Manufacturer`
- Model: Retrieved from `Win32_ComputerSystem.Model`

#### Special Handling
- **Lenovo Systems:** Uses `Win32_ComputerSystemProduct.Version` for accurate model detection
- **Unknown Hardware:** Continues with "Unknown" values but logs warnings

### Output Validation
The script validates successful export by checking:
- Total files exported
- Number of INF driver files
- Number of SYS driver files
- Organized folder structure
- Provider categorization

#### Sample Validation Output
```
Export validation results:
  Total files: 1,247
  INF files: 156
  SYS files: 289
  Organized categories: 12
    Audio: 3 providers
    Display: 2 providers
    Network: 4 providers
```

### Supported Operating Systems
- ✅ **Windows 11** - Full support
- ✅ **Windows 10** - Full support  
- ✅ **Windows 8.1** - Full support
- ✅ **Windows 8** - Full support
- ❌ **Windows 7** - Not supported (script will exit)

### Error Handling

#### Graceful Fallbacks
- DISM fallback if `Export-WindowsDriver` fails
- Generic logging if computer-specific logging unavailable
- Continues operation even if some drivers fail to organize

#### Exit Codes
- **0:** Successful completion
- **1:** Critical failure (unsupported OS, no drivers exported, etc.)

### Troubleshooting

#### Common Issues

**"No drivers were exported"**
- Check if running with administrator privileges
- Verify system has installable drivers (not inbox-only)
- Check DISM functionality: `dism /online /get-drivers`

**"Task sequence environment not available"**
- Ensure script is run from within MDT task sequence
- Check MDT integration and COM object availability

**"Permission denied to destination"**
- Verify write permissions to deployment share
- Check service account permissions
- Ensure destination drive has sufficient space

**"Unknown make/model detected"**
- Script will continue but may affect driver organization
- Check WMI functionality: `Get-CimInstance Win32_ComputerSystem`

#### Log Analysis

**Log File Location:**
- Primary: `[DeployShare]\Logs\[ComputerName]\Export-Drivers.ps1_[timestamp].log`
- Format: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`

**Log Levels:**
- **INFO:** Normal operations and success messages
- **WARN:** Non-critical issues, fallback usage
- **ERROR:** Critical failures requiring attention

### Performance Considerations

#### Network vs USB
- USB exports are typically faster due to local I/O
- Network exports enable centralized driver management
- Consider driver folder size when planning storage

#### Driver Count
- Modern systems can export 100-200+ drivers
- Export time varies based on driver count and storage speed
- Organized structure improves deployment performance

### Best Practices

#### Reference System Preparation
1. Install Windows with all latest updates
2. Install all manufacturer drivers (chipset, graphics, network, etc.)
3. Verify all hardware is working properly
4. Run Windows Update to get additional drivers
5. Execute Export-Drivers.ps1 to capture driver set

#### Driver Management
- Export drivers from each unique hardware model
- Regularly update driver exports when new driver versions are available
- Test exported drivers in deployment scenarios
- Monitor log files for export quality and completeness

#### Storage Planning
- Plan adequate storage space for organized driver folders
- Consider using ZIP archives for space efficiency (optional feature)
- Implement regular cleanup of old driver versions

### Version History
#### 2025.08.13-4
- Complete rewrite to match other script structures
- Added USB deployment share detection via media.tag
- Improved logging consistency and error handling
- Enhanced driver organization and validation

#### Previous Versions
- 2024.10.4-3: Basic export functionality
- 2024.10.4-2: Improved error handling and ZIP support
- 2024.10.4-1: MDT integration improvements
- 2024.3.14-2: Initial version

---

## UserExit-InstallWinPEDrivers.ps1

### Overview
PowerShell script for Microsoft Deployment Toolkit (MDT) that automatically installs hardware-specific drivers into the Windows PE environment during deployment. The script detects the computer make and model, then installs appropriate drivers from a structured driver repository using multiple installation methods for maximum compatibility.

### Version Information
- **Current Version**: 2025.08.07-11 (Fixed DISM Commands)
- **Author**: Stewart Bennell
- **License**: Copyright (c) Stewart Bennell. All rights reserved.

### Recent Updates (v2025.08.07-11)
- ✅ **Fixed DISM Commands**: Resolved error 0x80310000 by using proper WinPE installation methods
- ✅ **Multiple Installation Methods**: PnPUtil (preferred), DISM online, and legacy fallback methods
- ✅ **Enhanced Validation**: Comprehensive hardware detection and driver verification
- ✅ **Improved Error Handling**: Better logging and graceful fallback between installation methods
- ✅ **USB Deployment Support**: Optimized for USB-based WinPE deployments
- ✅ **Performance Improvements**: Reduced duplicate processing and added installation delays

### Purpose
- Installs drivers from "Drivers\WinPE" into the running Windows PE environment
- Provides hardware-specific driver installation based on computer make/model detection
- Falls back to generic drivers when specific hardware isn't recognized
- Uses multiple driver installation methods for maximum compatibility
- Comprehensive logging for troubleshooting deployment issues

### Requirements

#### System Requirements
- Windows PE environment (WinPE 10.0 or later recommended)
- Microsoft Deployment Toolkit (MDT) or System Center Configuration Manager (SCCM)
- PowerShell execution in WinPE
- Administrative privileges
- PnPUtil.exe (included in WinPE)

#### Driver Repository Structure
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

### Key Features

#### Core Functionality
- **Environment Detection**: Validates Windows PE environment before execution
- **Hardware Detection**: Identifies computer make and model using WMI/CIM
- **Special Lenovo Support**: Uses `Win32_ComputerSystemProduct.Version` for accurate Lenovo model detection
- **Flexible Driver Location**: Supports both network (MDT) and local (USB) driver repositories
- **Intelligent Driver Matching**: Multiple fallback strategies for driver location
- **Comprehensive Logging**: Detailed logging with timestamps and severity levels

#### Driver Installation Methods (New in v2025.08.07-11)
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

#### Driver Installation Strategies
1. **Exact Match**: `Make\Model` folder structure
2. **Partial Match**: Wildcard matching for similar model names  
3. **Generic Fallback**: Universal drivers when specific hardware isn't found
4. **Multiple Locations**: Network share or local USB drive support

#### Enhanced Validation & Hardware Detection
- **Driver Installation Verification**: Uses PnPUtil to confirm successful installations
- **Storage Controller Detection**: Validates storage hardware recognition
- **Disk Drive Enumeration**: Confirms disk access for deployment
- **Network Adapter Detection**: Checks for network hardware (USB deployments show "normal" status)

### Installation & Usage

#### 1. Setup Driver Repository
Create the driver folder structure in your MDT deployment share:
```
\\DeploymentServer\DeploymentShare$\Drivers\WinPE\
```

Or for USB deployments:
```
D:\Drivers\WinPE\
```

#### 2. Organize Drivers by Hardware
- Create folders using manufacturer names (Dell, HP, Lenovo, etc.)
- Create subfolders using clean model names (no special characters)
- Place .inf files and associated driver files in appropriate folders
- Test with known hardware (script tested successfully with LENOVO ThinkPad L13)

#### 3. Deploy Script
Place the script in your MDT Scripts folder or USB drive:
```
\\DeploymentServer\DeploymentShare$\Scripts\Extras\UserExit-InstallWinPEDrivers\UserExit-InstallWinPEDrivers.ps1
```

#### 4. Task Sequence Integration (Recommended Method)
Use "Run PowerShell Script" step in your MDT task sequence:
- **PowerShell script**: `UserExit-InstallWinPEDrivers.ps1`
- **PowerShell parameters**: (leave blank)
- **Run this step**: Early in WinPE phase, before imaging operations
- **Continue on error**: Optional (script provides detailed logging)

#### 5. Alternative: MDT UserExit Method
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

#### 6. USB Deployment Support  
For USB-based deployments:
- Ensure driver structure exists on USB drive: `D:\Drivers\WinPE\`
- Script automatically detects and uses local drivers

### Configuration

#### Logging Configuration
Logs are automatically created in:
- **Logging**: `X:\MININT\SMSOSD\OSDLOGS\`
- **USB/Local**: First available drive `\MININT\SMSOSD\OSDLOGS\`

Log filename format: `UserExit-InstallWinPEDrivers_YYYYMMDD_HHMMSS.log`

#### Sample Successful Log Output
```
[2025-07-21 11:42:42] [INFO] Found exact match path: D:\Drivers\WinPE\LENOVO\ThinkPad L13
[2025-07-21 11:42:42] [INFO] Found 8 driver files in: D:\Drivers\WinPE\LENOVO\ThinkPad L13
[2025-07-21 11:42:42] [INFO] Successfully installed with PnPUtil: HdBusExt.inf
[2025-07-21 11:42:48] [INFO] Driver installation completed. Success: 8/8
[2025-07-21 11:42:49] [INFO] Storage controllers detected: 2
[2025-07-21 11:42:49] [INFO] Disk drives detected: 2
```

### Troubleshooting

#### Common Issues & Solutions

**Script Not Running**
- **Cause**: PowerShell execution policy or permissions
- **Solution**: Ensure PowerShell scripts are allowed in WinPE boot image
- **Verification**: Check for script execution in logs

**No Drivers Found**
- **Cause**: Incorrect folder structure or naming
- **Solution**: Check folder names match detected make/model in logs
- **Debug**: Enable debug logging to see path resolution

**Network Path Unavailable**  
- **Cause**: Network connectivity issues in WinPE
- **Solution**: Use USB deployment method or ensure network drivers in boot image
- **USB Alternative**: Script automatically falls back to local drive detection

**Partial Driver Installation**
- **Cause**: Some drivers incompatible with WinPE or hardware
- **Expected**: Normal behavior - script continues with compatible drivers
- **Verification**: Check success count in logs (e.g., "Success: 6/8")

#### USB Deployment Notes
For USB-based deployments, these are **normal and expected**:
- "No network adapters detected (normal for USB-based WinPE deployment)"
- Script runs offline using drivers from USB drive
- Storage and disk detection should work properly

#### Log Analysis Examples

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

### Error Handling
- Graceful fallback when Task Sequence environment unavailable
- Continues execution even if individual drivers fail
- Multiple installation method attempts per driver
- Detailed error logging for troubleshooting
- Proper exit codes for automation

### Exit Codes
- **0**: Success - All operations completed successfully
- **1**: Error - Critical failure (not in WinPE, no drivers path, no drivers installed)

### Performance & Best Practices

#### Driver Management
- Test drivers in WinPE environment before deployment
- Keep generic/universal drivers as fallback
- Regularly update drivers for new hardware models
- Use manufacturer driver packs when available
- Organize by exact model names for best matching

#### Deployment Optimization
- Run early in task sequence after basic hardware initialization
- Monitor logs for successful driver installation patterns
- Use USB deployment for offline scenarios
- Test with various hardware models before production use
- Include storage and network drivers as priority

#### Folder Organization Best Practices
- Use consistent naming conventions across all manufacturers
- Group similar models in manufacturer folders
- Maintain separate WinPE and full Windows driver repositories
- Document driver versions and update dates
- Test folder structure with actual hardware detection

### Version History
- **2025.08.07-11**: Fixed DISM commands, multiple installation methods, enhanced validation
- **2025.8.5-10**: Initial PowerShell version with comprehensive logging and error handling
- **2025.07.29-6**: Previous version

---

## Integration with Other Scripts

These three scripts are designed to work together as a complete MDT driver management solution:

- **Export-Drivers.ps1:** Captures drivers from reference systems
- **UserExit-InstallWinPEDrivers.ps1:** Installs WinPE drivers for hardware detection and deployment
- **Copy-Drivers.ps1:** Deploys full Windows drivers during OS installation

All scripts share common logging, error handling, and path detection patterns for consistent operation.

## Support & Development

For issues or questions regarding these scripts:
- Review log files for detailed error information and success patterns
- Verify driver repository structure and permissions
- Test scripts manually in appropriate environments
- Check MDT documentation for PowerShell script requirements
- Consider USB deployment method for offline scenarios

## License

Copyright (c) Stewart Bennell. All rights reserved.

These scripts are provided as-is without warranty. Use in production environments should be thoroughly tested.
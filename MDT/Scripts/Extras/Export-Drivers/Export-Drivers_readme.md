# Export-Drivers.ps1

**Version: 2025.08.13-4**  
**Copyright (c) Stewart Bennell. All rights reserved.**

A PowerShell script for exporting and organizing system drivers from a reference computer into the Microsoft Deployment Toolkit (MDT) drivers folder structure.

## Purpose

Export drivers from the current system and organize them in the DeployShare drivers folder structure for use with MDT deployments. This script is designed to be run on a fully configured reference system to capture all necessary drivers for deployment to similar hardware.

## Key Features

### Driver Export
- Exports all installed system drivers using `Export-WindowsDriver` cmdlet
- DISM fallback method for compatibility
- Automatic exclusion of printer drivers
- Comprehensive validation of export results

### Intelligent Path Detection
- **Network Deployment:** Uses task sequence `DeployRoot` for network-based deployments
- **USB Detection:** Automatically detects USB media via `media.tag` in `Deploy\Scripts\` folder
- **Smart Selection:** Prioritizes USB storage when running from USB media

### Driver Organization
- Organizes drivers by device class (Audio, Display, Network, etc.)
- Sub-organizes by provider/manufacturer
- Sanitizes folder names for filesystem compatibility
- Creates clean, browsable folder structure

### Robust Logging
- Computer-specific log folders when available
- Timestamped entries with multiple log levels (INFO, WARN, ERROR)
- Detailed operation tracking and error reporting
- Comprehensive validation results

## Folder Structure Created

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

## Usage

### Prerequisites
- Run on a fully configured reference system
- All necessary drivers installed and working
- MDT task sequence environment available
- Appropriate permissions to deployment share

### Execution
```powershell
# Run from MDT task sequence
.\Export-Drivers.ps1

# Or run directly in PowerShell (with MDT environment)
.\Export-Drivers.ps1
```

### Task Sequence Integration
1. Add "Run PowerShell Script" step in MDT task sequence
2. Script Path: `Scripts\Export-Drivers.ps1`
3. PowerShell execution policy: `Bypass`
4. Place after all drivers are installed and system is fully configured

## Deployment Scenarios

### Network Deployment
When running from network deployment share:
- Uses `DeployRoot` from task sequence
- Saves to: `\\server\DeployShare\Drivers\[OS]\[MAKE]\[MODEL]\`
- Logs to: `\\server\DeployShare\Logs\[ComputerName]\`

### USB Deployment
When running from USB media (detected via `media.tag`):
- Uses local USB path: `[USB]:\Deploy\Drivers\[OS]\[MAKE]\[MODEL]\`
- Logs to: `[USB]:\Deploy\Logs\[ComputerName]\`
- Enables offline driver capture scenarios

## Required Task Sequence Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DeployRoot` | Path to deployment share | `\\server\DeployShare` or `E:\Deploy` |
| `OSDComputerName` | Computer name for logging | `REF-COMPUTER-01` |

*Note: Script will work without `OSDComputerName` but will use generic log folder*

## Hardware Detection

### Standard Detection
- Make: Retrieved from `Win32_ComputerSystem.Manufacturer`
- Model: Retrieved from `Win32_ComputerSystem.Model`

### Special Handling
- **Lenovo Systems:** Uses `Win32_ComputerSystemProduct.Version` for accurate model detection
- **Unknown Hardware:** Continues with "Unknown" values but logs warnings

## Output Validation

The script validates successful export by checking:
- Total files exported
- Number of INF driver files
- Number of SYS driver files
- Organized folder structure
- Provider categorization

### Sample Validation Output
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

## Supported Operating Systems

- ✅ **Windows 11** - Full support
- ✅ **Windows 10** - Full support  
- ✅ **Windows 8.1** - Full support
- ✅ **Windows 8** - Full support
- ❌ **Windows 7** - Not supported (script will exit)

## Error Handling

### Graceful Fallbacks
- DISM fallback if `Export-WindowsDriver` fails
- Generic logging if computer-specific logging unavailable
- Continues operation even if some drivers fail to organize

### Exit Codes
- **0:** Successful completion
- **1:** Critical failure (unsupported OS, no drivers exported, etc.)

## Troubleshooting

### Common Issues

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

### Log Analysis

**Log File Location:**
- Primary: `[DeployShare]\Logs\[ComputerName]\Export-Drivers.ps1_[timestamp].log`
- Format: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`

**Log Levels:**
- **INFO:** Normal operations and success messages
- **WARN:** Non-critical issues, fallback usage
- **ERROR:** Critical failures requiring attention

### Performance Considerations

**Network vs USB:**
- USB exports are typically faster due to local I/O
- Network exports enable centralized driver management
- Consider driver folder size when planning storage

**Driver Count:**
- Modern systems can export 100-200+ drivers
- Export time varies based on driver count and storage speed
- Organized structure improves deployment performance

## Integration with Other Scripts

This script is designed to work with:
- **Copy-Drivers.ps1:** Deploys the exported drivers during OS installation
- **UserExit-InstallWinPEDrivers.ps1:** Uses WinPE drivers for hardware detection

All scripts share common logging, error handling, and path detection patterns.

## Version History

### 2025.08.13-4
- Complete rewrite to match other script structures
- Added USB deployment share detection via media.tag
- Improved logging consistency and error handling
- Enhanced driver organization and validation

### Previous Versions
- 2024.10.4-3: Basic export functionality
- 2024.10.4-2: Improved error handling and ZIP support
- 2024.10.4-1: MDT integration improvements
- 2024.3.14-2: Initial version

## Best Practices

### Reference System Preparation
1. Install Windows with all latest updates
2. Install all manufacturer drivers (chipset, graphics, network, etc.)
3. Verify all hardware is working properly
4. Run Windows Update to get additional drivers
5. Execute Export-Drivers.ps1 to capture driver set

### Driver Management
- Export drivers from each unique hardware model
- Regularly update driver exports when new driver versions are available
- Test exported drivers in deployment scenarios
- Monitor log files for export quality and completeness

### Storage Planning
- Plan adequate storage space for organized driver folders
- Consider using ZIP archives for space efficiency (optional feature)
- Implement regular cleanup of old driver versions

## License

Copyright (c) Stewart Bennell. All rights reserved.

This script is provided as-is without warranty. Use in production environments should be thoroughly tested.
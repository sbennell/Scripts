# Intune Autopilot App Removal Script

## Overview

This PowerShell script automatically removes unwanted Windows applications during Microsoft Intune Autopilot deployment. It targets common bloatware and non-essential apps to provide a cleaner Windows experience for enterprise users.

## Features

- **Automated Removal**: Removes 23 common Windows apps including Xbox, Bing apps, and consumer-focused applications
- **Comprehensive Logging**: Detailed JSON-formatted logs for troubleshooting and audit purposes
- **Registry Detection**: Creates a registry key for Intune deployment tracking
- **Error Handling**: Continues processing even if individual app removals fail
- **Autopilot Integration**: Designed specifically for deployment during Windows Autopilot provisioning

## Removed Applications

The script targets the following applications:

- **Bing Apps**: Bing Search, Bing News, Bing Weather, Bing Maps
- **Xbox/Gaming**: Xbox App, Xbox Game Overlay, Xbox Gaming Overlay, Xbox Identity Provider, Xbox Speech-to-Text, Gaming App
- **Communication**: Skype, Your Phone, People
- **Productivity**: OneNote, Outlook for Windows, Office Hub
- **Utilities**: Feedback Hub, Get Help, Get Started, Wallet
- **Entertainment**: Microsoft Solitaire Collection
- **Development**: Dev Home

## Prerequisites

- Windows 10/11 Enterprise or Pro
- Microsoft Intune subscription
- PowerShell execution rights during Autopilot deployment
- Administrative privileges (automatically available during Autopilot)

## Deployment Methods

### Method 1: Win32 App (Recommended)

1. **Prepare the package:**
   ```cmd
   # Create Install.cmd wrapper
   @echo off
   PowerShell.exe -ExecutionPolicy Bypass -File "RemoveApps.ps1"
   ```

2. **Create .intunewin package:**
   - Use Microsoft Win32 Content Prep Tool
   - Package both `RemoveApps.ps1` and `Install.cmd`

3. **Configure in Intune:**
   - **App Type**: Windows app (Win32)
   - **Install Command**: `Install.cmd`
   - **Uninstall Command**: `cmd /c echo "No uninstall required"`
   - **Install Behavior**: System
   - **Device Restart Behavior**: No specific action

4. **Detection Rule:**
   - **Type**: Registry
   - **Path**: `HKLM:\Software\SOE\RemovePackages`
   - **Value Name**: `Version`
   - **Detection Method**: String comparison
   - **Operator**: Equals
   - **Value**: `1.0.0`

### Method 2: PowerShell Script

1. **Upload to Intune:**
   - Navigate to **Devices** > **Scripts** > **Add**
   - Upload `RemoveApps.ps1`

2. **Configuration:**
   - **Run using logged on credentials**: No
   - **Enforce script signature check**: No
   - **Run in 64-bit PowerShell**: Yes

3. **Assignment:**
   - Assign to Autopilot device groups
   - Set as **Required**

### Method 3: Autopilot Profile Integration

Include the script content directly in your Autopilot deployment profile as a custom PowerShell script.

## File Structure

```
RemoveApps/
├── RemoveApps.ps1          # Main PowerShell script
├── Install.cmd             # Batch wrapper for Win32 deployment
├── README.md               # This documentation
└── detection.ps1           # Optional: Standalone detection script
```

## Logging

### Log Location
- **File**: `%TEMP%\RemovePackages.log`
- **Format**: JSON (one object per line)
- **Encoding**: UTF-8

### Log Content
Each log entry contains:
```json
{
  "Selector": "Microsoft.XboxApp",
  "Timestamp": "2025-08-19 14:30:22",
  "Message": "Package removed successfully.",
  "Output": "removal_details_object"
}
```

### Log Analysis
To analyze logs after deployment:
```powershell
# View successful removals
Get-Content "$env:TEMP\RemovePackages.log" | ConvertFrom-Json | Where-Object {$_.Message -like "*removed successfully*"}

# View failures
Get-Content "$env:TEMP\RemovePackages.log" | ConvertFrom-Json | Where-Object {$_.Message -like "*failed*"}
```

## Registry Detection

The script creates a registry entry for Intune detection:

- **Path**: `HKLM:\Software\SOE\RemovePackages`
- **Name**: `Version`
- **Type**: String
- **Value**: `1.0.0`

This registry key serves as proof of successful script execution for Intune compliance reporting.

## Best Practices

### Timing
- Deploy during **Device ESP (Enrollment Status Page)** phase
- Run before user first logon for best results
- Consider running in the **Device Setup** phase of Autopilot

### Testing
1. **Pilot Group**: Test with a small group of devices first
2. **Verification**: Check logs and verify app removal post-deployment
3. **Rollback Plan**: Maintain ability to reinstall apps if needed

### Customization
To modify the app list:
1. Add/remove entries from the `$selectors` array
2. Update the version number in the registry creation section
3. Test thoroughly before production deployment

## Troubleshooting

### Common Issues

**Script doesn't run:**
- Verify PowerShell execution policy allows script execution
- Check Intune assignment targeting
- Ensure device has internet connectivity during Autopilot

**Apps not removed:**
- Some apps may be reinstalled by Windows Update
- Consider using AppLocker or Windows Package Manager policies
- Verify the app package names are correct

**Detection rule fails:**
- Confirm registry path permissions
- Check if script completed execution
- Review PowerShell script execution logs

### Verification Commands

```powershell
# Check if registry key exists
Get-ItemProperty -Path "HKLM:\Software\SOE\RemovePackages" -Name "Version" -ErrorAction SilentlyContinue

# List remaining provisioned packages
Get-AppxProvisionedPackage -Online | Select-Object DisplayName | Sort-Object DisplayName

# Check script execution in Event Viewer
Get-WinEvent -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Operational" | Where-Object {$_.Message -like "*PowerShell*"}
```

## Version History

- **v1.0.0**: Initial release with 23 target applications and registry detection

## Support

For issues related to:
- **Script functionality**: Review logs in `%TEMP%\RemovePackages.log`
- **Intune deployment**: Check Microsoft Endpoint Manager admin center
- **Autopilot integration**: Verify device group assignments and ESP configuration

## Security Considerations

- Script runs with SYSTEM privileges during Autopilot
- Only removes Microsoft-published applications
- Does not modify system-critical components
- Logs all actions for audit compliance
- Uses standard Windows PowerShell cmdlets only
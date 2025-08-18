# Lock Screen Info (BGInfo Replacement)

This project displays essential system information on a custom lock screen background using PowerShell and HTML. It's a modern replacement for BGInfo, optimized for Windows environments like schools or offices.

## Features

- Custom background with organization branding
- Displays hostname, manufacturer, model, serial number, and install date
- **Dynamic font sizing based on screen resolution** - automatically scales fonts for different displays
- Clean and responsive HTML design with CSS styling
- Uses `wkhtmltoimage` to generate lock screen images
- Enhanced model detection for Lenovo systems (uses Win32_ComputerSystemProduct.Version)
- Supports multiple screen resolutions and aspect ratios
- Multiple layout options (bottom-left, bottom-right, top-left, top-right)
- Comprehensive logging for troubleshooting

## Requirements

- Windows 7/10/11
- PowerShell
- wkhtmltopdf/wkhtmltoimage binaries:
  - `wkhtmltoimage.exe`
  - `wkhtmltox.dll`
  - `libwkhtmltox.a`
  
  All files must be in the same directory as the script.

## Installation

1. **Prepare Directory Structure** (Optional - Auto-created)
   ```
   C:\Windows\OEMFiles\
   ├── Wallpaper\
   │   └── wallpaper.jpg
   ├── lockscreen\
   │   └── (generated files will be placed here)
   └── logs\
       └── (log files will be placed here)
   ```
   
   **Note:** The script automatically creates the OEMFiles directory structure if it doesn't exist. You only need to manually create the Wallpaper directory and place your wallpaper file.

2. **Place Required Files**
   - Save your custom wallpaper at: `C:\Windows\OEMFiles\Wallpaper\wallpaper.jpg`
   - Place the following files in the same directory:
     - `LockScreenInfo.ps1`
     - `format_bottom_left.html`
     - `format_bottom_right.html`
     - `format_top_left.html`
     - `format_top_right.html`
     - `wkhtmltoimage.exe`
     - `wkhtmltox.dll`
     - `libwkhtmltox.a`

3. **Customize HTML Templates**
   - Edit any of the format HTML files to change styling or layout
   - The script uses PowerShell variable expansion to inject system information
   - **Dynamic font sizing variables:**
     - `$BaseFontSize` - Main text font size (automatically calculated)
     - `$OrganizationFontSize` - Larger font for organization/hostname (automatically calculated)
   - Other supported variables include:
     - `$Hostname` - Computer name
     - `$($COMPUTERSYSTEM.Manufacturer)` - System manufacturer
     - `$($COMPUTERSYSTEM.Model)` - System model
     - `$SerialNum` - BIOS serial number
     - `$Script:InstallDate` - OS installation date
     - `$Script:Contact` - Contact information from parameter
     - `$Script:Organization` - Organization name from parameter
     - `$BackgroundImage` - Background image path (converted to file:// URL format)

## Usage

### Basic Usage
```powershell
# Default layout (bottom-right)
.\LockScreenInfo.ps1

# Specific layout
.\LockScreenInfo.ps1 -HTMLPath "format_top_left.html"
```

### Font Size Control
```powershell
# Default dynamic sizing (recommended)
.\LockScreenInfo.ps1

# Make fonts 20% smaller for high-DPI displays
.\LockScreenInfo.ps1 -FontSizeMultiplier 0.8

# Make fonts 30% larger for better visibility
.\LockScreenInfo.ps1 -FontSizeMultiplier 1.3

# Custom organization with adjusted fonts
.\LockScreenInfo.ps1 -Organization "Primary School" -FontSizeMultiplier 1.2
```

### Organization and Contact Information
```powershell
# Add organization name
.\LockScreenInfo.ps1 -Organization "Primary School"

# Add contact information
.\LockScreenInfo.ps1 -ContactInfo "IT Help: (555) 123-4567 | itsupport@email.vic.edu.au"

# Hide organization or contact info
.\LockScreenInfo.ps1 -HideOrganization -HideContact
```

### Complete Example
```powershell
.\LockScreenInfo.ps1 -HTMLPath "format_top_right.html" -Organization "Primary School" -ContactInfo "IT Support: ext. 1234" -FontSizeMultiplier 1.1 -BackgroundImage "C:\Custom\school-logo.jpg"
```

### Parameters
- `-TargetImage`: Output path for the generated lock screen image (default: `$env:SYSTEMROOT\OEMFiles\lockscreen\lockscreen.jpg`)
- `-HTMLPath`: Path to the HTML template file (default: `format_Bottom_Right.html`)
- `-BackgroundImage`: Path to the background wallpaper image (default: `$env:SYSTEMROOT\OEMFiles\Wallpaper\wallpaper.jpg`)
- `-Organization`: Organization name to display
- `-HideOrganization`: Hide organization name completely
- `-ContactInfo`: Contact information to display
- `-HideContact`: Hide contact information completely
- `-FontSizeMultiplier`: Adjust font sizes (default: 1.0, range: 0.5-2.0 recommended)

## Dynamic Font Sizing

The script automatically calculates appropriate font sizes based on your screen resolution, ensuring text remains readable across different display sizes.

### Font Scaling Examples by Resolution:
- **1366x768** (laptop): ~13pt base, ~17pt organization
- **1920x1080** (standard): 16pt base, 20pt organization  
- **2560x1440** (2K): ~21pt base, ~27pt organization
- **3840x2160** (4K): ~32pt base, ~40pt organization

### Customizing Font Sizes:
- **Too small?** Use `-FontSizeMultiplier 1.2` or higher
- **Too large?** Use `-FontSizeMultiplier 0.8` or lower
- **Perfect as-is?** No parameter needed - uses optimal sizing

The scaling algorithm:
1. Uses 1920x1080 as reference resolution (16pt base font)
2. Calculates scaling factor based on screen area and aspect ratio
3. Applies constraints (0.6x to 2.0x) to prevent extreme sizes
4. Applies user multiplier for fine-tuning

## Layout Options

Choose from four different layout positions:

1. **Bottom Right** (`format_bottom_right.html`) - Default, traditional placement
2. **Bottom Left** (`format_bottom_left.html`) - Alternative corner placement
3. **Top Right** (`format_top_right.html`) - Upper corner, avoids taskbar area
4. **Top Left** (`format_top_left.html`) - Upper left, clean appearance

Each layout automatically adapts font sizes to the screen resolution.

## How It Works

1. **System Information Gathering**: The script uses WMI queries to collect system details including:
   - Computer system information (name, manufacturer, model)
   - Enhanced model detection for Lenovo systems (uses Win32_ComputerSystemProduct.Version)
   - BIOS information (serial number)
   - Operating system details (install date, boot time)
   - Screen resolution for proper image sizing

2. **Dynamic Font Calculation**:
   - Detects current screen resolution
   - Calculates appropriate font scaling based on display size
   - Applies user-specified multiplier if provided
   - Logs font scaling decisions for troubleshooting

3. **HTML Processing**: 
   - Loads the selected HTML template
   - Converts background image path to proper file:// URL format
   - Injects calculated font sizes into CSS
   - Replaces template variables with actual values
   - Expands PowerShell variables within the HTML content
   - Saves the processed HTML to a temporary file

4. **Image Generation**:
   - Uses `wkhtmltoimage` to convert the HTML to a JPG image
   - Uses detected screen resolution for proper sizing
   - Outputs the final lock screen image

## Advanced Features

### Contact Information
The script supports displaying contact information through the `-ContactInfo` parameter:

```powershell
# Simple contact info
.\LockScreenInfo.ps1 -ContactInfo "IT Help Desk: (555) 123-4567"

# Multiple contact methods
.\LockScreenInfo.ps1 -ContactInfo "IT Help: (555) 123-4567 | support@school.edu | ext. 1234"
```

### Logging
The script generates detailed logs at:
```
C:\Windows\OEMFiles\logs\LockScreenInfo.log
```

The OEMFiles directory structure is automatically created if it doesn't exist, including:
- `C:\Windows\OEMFiles\` (main directory)
- `C:\Windows\OEMFiles\logs\` (log files directory)

Logs include:
- Screen resolution detection
- Font scaling calculations
- System information gathering
- File operations
- Error conditions

### Font Size Troubleshooting
If fonts appear too small or large:

1. **Check the log file** for font scaling information:
   ```
   [info] Font scaling calculation:
   [info]   Current resolution: 1920x1080
   [info]   Reference resolution: 1920x1080
   [info]   Scaling factor: 1.000
   [info]   User multiplier: 1.0
   [info]   Base font size: 16pt
   [info]   Organization font size: 20pt
   ```

2. **Adjust with multiplier**:
   - For 4K displays that look too small: `-FontSizeMultiplier 1.5`
   - For small laptops that look too large: `-FontSizeMultiplier 0.7`

3. **Test different layouts** - some positions work better on certain screen sizes

## Deployment

### Option 1: Scheduled Task
Create a scheduled task to run the script:
- At system startup
- At user logon
- On a regular interval (e.g., daily)

Example scheduled task command:
```cmd
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Scripts\LockScreenInfo.ps1" -Organization "Your Organization" -FontSizeMultiplier 1.1
```

### Option 2: Group Policy
Deploy via GPO using:
- Computer Configuration > Windows Settings > Scripts > Startup
- User Configuration > Windows Settings > Scripts > Logon

### Option 3: Manual Execution
Run the script manually when system information changes or for testing different font sizes.

## Customization Examples

### Adding IP Address
Add to the PowerShell script:
```powershell
$Script:IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | 
    Select-Object -First 1).IPAddress
```

Then add to your HTML template:
```html
<p>IP Address: $Script:IPAddress</p>
```

### Adding Uptime
Add to the PowerShell script:
```powershell
$Script:Uptime = (Get-Date) - $Script:LastBootTime
$Script:UptimeFormatted = "$($Script:Uptime.Days) days, $($Script:Uptime.Hours) hours"
```

### Custom CSS for Different Resolutions
You can create resolution-specific templates:

```html
<style type="text/css">
/* Base styles with dynamic font sizing */
html, body { 
  font-size: $BaseFontSize;
  /* ... other styles ... */
}

.organization {
  font-size: $OrganizationFontSize;
  /* ... other styles ... */
}

/* Additional responsive adjustments if needed */
@media screen and (min-width: 3840px) {
  .info-box {
    padding: 1em 1em; /* More padding on 4K displays */
  }
}
</style>
```

### Using Different Background Images by Resolution
```powershell
# Choose background based on resolution
if ($ScreenWidth -ge 3840) {
    $BackgroundImage = "C:\Backgrounds\4K-background.jpg"
} elseif ($ScreenWidth -ge 2560) {
    $BackgroundImage = "C:\Backgrounds\2K-background.jpg"
} else {
    $BackgroundImage = "C:\Backgrounds\HD-background.jpg"
}

.\LockScreenInfo.ps1 -BackgroundImage $BackgroundImage
```

### Manufacturer-Specific Features

#### Lenovo Systems
For Lenovo computers, the script automatically uses enhanced model detection:
- **Standard Model Field**: Often shows generic codes like "20378" or "10AA"
- **Enhanced Model Field**: Shows descriptive names like "ThinkPad T14 Gen 2" or "ThinkCentre M720s"
- **Automatic Detection**: Script detects Lenovo manufacturer and uses `Win32_ComputerSystemProduct.Version` for better model information
- **Fallback Protection**: If enhanced detection fails, falls back to standard model field

Example improvement:
```
Before: Model: 20378
After:  Model: ThinkPad T14 Gen 2
```

### Custom Styling for Different Organizations
Create organization-specific templates with custom colors and fonts:

```html
<style type="text/css">
html, body { 
  font-size: $BaseFontSize;
  /* School theme - blue and white */
  color: #ffffff;
  text-shadow: 2px 2px 4px #003366;
}

.info-box {
  background-color: rgba(0, 51, 102, 0.8); /* School blue */
  border: 2px solid #ffffff;
  border-radius: 12px;
}

.organization {
  font-size: $OrganizationFontSize;
  color: #ffcc00; /* School gold */
  font-weight: bold;
}
</style>
```

## Troubleshooting

1. **Check Log Files**: Review `C:\Windows\OEMFiles\logs\LockScreenInfo.log` for errors
2. **Font Size Issues**: 
   - Check resolution detection in logs
   - Try different `-FontSizeMultiplier` values
   - Test with different HTML templates
3. **Verify wkhtmltoimage Dependencies**: Ensure all required files are present:
   - `wkhtmltoimage.exe`
   - `wkhtmltox.dll`
   - `libwkhtmltox.a`
4. **Test HTML**: Open the generated HTML file manually to verify content and font sizes
5. **Screen Resolution**: Script automatically detects resolution, but logs the values used
6. **File Permissions**: Ensure write permissions to the target directories

### Common Font Sizing Issues:

**Problem**: Fonts too small on 4K displays
**Solution**: Use `-FontSizeMultiplier 1.5` or higher

**Problem**: Fonts too large on small laptops  
**Solution**: Use `-FontSizeMultiplier 0.7` or lower

**Problem**: Inconsistent sizing across multiple monitors
**Solution**: Script uses primary monitor resolution; consider separate configurations for different systems

## File Structure
```
Project Directory/
├── LockScreenInfo.ps1              # Main PowerShell script with dynamic font sizing
├── format_bottom_left.html         # Bottom-left layout template
├── format_bottom_right.html        # Bottom-right layout template (default)
├── format_top_left.html            # Top-left layout template
├── format_top_right.html           # Top-right layout template
├── wkhtmltoimage.exe               # HTML to image converter
├── wkhtmltox.dll                   # wkhtmltopdf library (Windows)
├── libwkhtmltox.a                  # wkhtmltopdf static library
└── README.md                       # This documentation
```

## Version History
- **08/11/2011** - RIVIERRE Frédéric (VortiFred) - Initial version
- **01/03/2012** - RIVIERRE Frédéric (VortiFred) - Updates and improvements
- **07/11/2014** - RIVIERRE Frédéric (VortiFred) - Feature enhancements
- **11/07/2019** - David Search (WSUTC) - Major updates and modernization
- **10/09/2022** - Stewart Bennell - Code modifications and optimizations
- **24/07/2025** - Stewart Bennell - Enhanced parameter support, improved HTML template handling, multiple format options (bottom-left, bottom-right, top-left, top-right), organization and contact info customization, better Lenovo model detection, refined logging system
- **25/07/2025** - Stewart Bennell - **Added dynamic font sizing based on screen resolution**, automatic font scaling algorithm, FontSizeMultiplier parameter for fine-tuning, comprehensive font scaling logging, resolution-aware layouts
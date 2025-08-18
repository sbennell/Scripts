# Detection script for LockScreenInfo deployment
# Save as: detect.ps1

$RequiredFiles = @(
    "C:\Windows\OEMFiles\Scripts\LockScreenInfo.ps1",
    "C:\Windows\OEMFiles\Scripts\format_bottom_left.html",
    "C:\Windows\OEMFiles\Scripts\format_Bottom_Right.html",
    "C:\Windows\OEMFiles\Scripts\format_top_left.html",
    "C:\Windows\OEMFiles\Scripts\format_top_right.html",
    "C:\Windows\OEMFiles\Scripts\wkhtmltoimage.exe",
    "C:\Windows\OEMFiles\Scripts\wkhtmltox.dll",
    "C:\Windows\OEMFiles\Scripts\libwkhtmltox.a"
		
)

$TaskName = "LockScreenInfo"

# Check if all required files exist
$FilesExist = $true
foreach ($file in $RequiredFiles) {
    if (!(Test-Path $file)) {
        $FilesExist = $false
        break
    }
}

# Check if scheduled task exists
$TaskExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($FilesExist -and $TaskExists) {
    Write-Host "LockScreenInfo is installed"
    exit 0
} else {
    exit 1
}
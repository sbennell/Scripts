# Get system uptime
$lastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $lastBoot

# Check if uptime exceeds 14 days
if ($uptime.Days -ge 14) {
    Write-Output "Reboot required"
    exit 1  # indicates remediation required
} else {
	Write-Output "Reboot not required"
    exit 0  # system is OK
}

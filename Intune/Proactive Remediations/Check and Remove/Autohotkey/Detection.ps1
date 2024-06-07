$app_2upgrade = "AutoHotkey.AutoHotkey"

# resolve and navigate to winget.exe
$Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\winget.exe")

if ($(&$winget list --accept-source-agreements) -like "* $app_2upgrade *") {
	Write-Host "yes $app_2upgrade is installed"
	exit 1 # yes, remediation needed
}
else {
	Write-Host "uninstall not available for: $app_2upgrade"
	exit 0 # no uninstall needed, no action needed
}
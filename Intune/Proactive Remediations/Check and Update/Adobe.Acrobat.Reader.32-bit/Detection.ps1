$app_2upgrade = "Adobe.Acrobat.Reader.32-bit"

# resolve and navigate to winget.exe
$Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\winget.exe")

if ($(&$winget upgrade --accept-source-agreements) -like "* $app_2upgrade *") {
	Write-Host "Upgrade available for: $app_2upgrade"
	exit 1 # upgrade available, remediation needed
}
else {
	Write-Host "No Upgrade available"
	exit 0 # no upgrade, no action needed
}
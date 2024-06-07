﻿$app_2remove = "Microsoft.Teams"

try{
    # resolve and navigate to winget.exe
    $Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\winget.exe")

    # uninstall command
    &$winget uninstall $app_2remove --silent --force
    exit 0

}catch{
    Write-Error "Error while installing uninstall for: $app_2remove"
    exit 1\\
}
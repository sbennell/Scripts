$app_2upgrade = "GIMP.GIMP"

try{
    # resolve and navigate to winget.exe
    $Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\winget.exe")

    # upgrade command
    &$winget upgrade --exact $app_2upgrade --silent --force --accept-package-agreements --accept-source-agreements

    ## Remove Desktop Shortcuts
    $DesktopSC = "$env:PUBLIC\desktop\Gimp*.lnk"
    If (Test-Path $DesktopSC) {
    	Remove-Item $DesktopSC -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    ## Remove Desktop Shortcuts
    If(Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\GIMP*.lnk") {
    	Move-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\GIMP*.lnk" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\GIMP.lnk"
    }

}catch{
    Write-Error "Error while installing upgrade for: $app_2upgrade"
    exit 1\\
}
#Powershell script to customize windows Before Frist boot
#Version 2020.5.1
#Stewart Bennell 24/05/2020
#

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$OSDisk = "$($tsenv.Value("OSDisk"))"
$OSDTargetSystemRoot = "$($tsenv.Value("OSDisk"))" + "\Windows"
 
#Loads the Default User Profile NTUSER.DAT file
Write-Host "Creating HKU Drive..." 
New-PSDrive HKU -Root HKEY_Users -PSProvider Registry
Write-Host "Loading Default user hive..."
REG LOAD HKU\Default $OSDisk\Users\Default\NTUSER.DAT

#Checking if HideDesktopIcons Exist in HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer
Write-Output "Checking for HideDesktopIcons"
$HideDesktopIcons = "Registry::HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\"
    If (!(Test-Path $HideDesktopIcons)) {
		Write-Output "Cant Find HideDesktopIcons."
        New-Item $HideDesktopIcons 
    }
Write-Output "Found HideDesktopIcons"


Write-Output "Checking for NewStartPanel"
$NewStartPanel = "Registry::HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel\"
    If (!(Test-Path $NewStartPanel)) {
		Write-Output "Cant Find NewStartPanel."
        New-Item $NewStartPanel 
    }
Write-Output "Found NewStartPanel"

Write-Output "Checking for ClassicStartMenu"
$ClassicStartMenu = "Registry::HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu\"
    If (!(Test-Path $ClassicStartMenu)) {
		Write-Output "Cant Find ClassicStartMenu. Going to create ClassicStartMenu"
        New-Item $ClassicStartMenu 
    }
Write-Output "Found ClassicStartMenu"

#Show This PC on Desktop
Write-Output "Show This PC on Desktop"
Set-ItemProperty $NewStartPanel "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0
Set-ItemProperty $ClassicStartMenu "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0

#Show User Files on Desktop 
Write-Output "Show User Files on Desktop"
Set-ItemProperty $NewStartPanel "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0
Set-ItemProperty $ClassicStartMenu "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0

#Show Network Icon on Desktop 
Write-Output "Show Network Icon on Desktop"
Set-ItemProperty $NewStartPanel "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0
Set-ItemProperty $ClassicStartMenu "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0

#Checking for AutoplayHandlers
Write-Output "Checking for AutoplayHandlers"
$AutoplayHandlers = "Registry::HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\"
    If (!(Test-Path $AutoplayHandlers)) {
		Write-Output "Cant Find AutoplayHandlers."
        New-Item $AutoplayHandlers 
    }
Write-Output "Found AutoplayHandlers"
#Disable Autoplay for all media and devices
Write-Output "Disable Autoplay for all media and devices"
Set-ItemProperty $AutoplayHandlers DisableAutoplay -Value 1

#Checking for Search
Write-Output "Checking for Search"
$Search = "Registry::HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\"
    If (!(Test-Path $Search)) {
		Write-Output "Cant Find Search."
        New-Item $Search 
    }
Write-Output "Found Search"
#Remove search bar and only show icon
Write-Output "Remove search bar and only show icon"
Set-ItemProperty $Search SearchboxTaskbarMode -Value 1

#Checking for People
Write-Output "Checking for People"
$People = "Registry::HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People\"
    If (!(Test-Path $People)) {
		Write-Output "Cant Find People."
        New-Item $People 
    }
Write-Output "Found People"
#Disables People icon on Taskbar
Write-Output "Disables People icon on Taskbar"
Set-ItemProperty $People PeopleBand -Value 0

#Checking for Advanced
Write-Output "Checking for Advanced"
$Advanced = "Registry::HKU\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\"
    If (!(Test-Path $Advanced)) {
		Write-Output "Cant Find Advanced."
        New-Item $Advanced 
    }
Write-Output "Found Advanced"

#Disables Cortana Buttion
Write-Output "Disables Cortana Buttion"
Set-ItemProperty $Advanced ShowCortanaButton -Value 0

#Set Default Folder When Opening Explorer to This PC
Write-Output "Set Default Folder When Opening Explorer to This PC"
Set-ItemProperty $Advanced LaunchTo -Value 1

#Show known file extensions
Write-Output "Show known file extensions"
Set-ItemProperty $Advanced HideFileExt -Value 0

#Checking for Winlogon
Write-Output "Checking for Winlogon"
$Winlogon = "Registry::HKU\Default\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
    If (!(Test-Path $Winlogon)) {
		Write-Output "Cant Find Winlogon."
        New-Item $Winlogon 
    }
Write-Output "Found Winlogon"
Write-Output "Turn Off Automatically Restart Apps After Sign-In"
Set-ItemProperty $Winlogon RestartApps -Value 0

#Checking for Ribbon
Write-Output "Checking for Ribbon"
$Ribbon = "Registry::HKU\Default\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Ribbon\"
    If (!(Test-Path $Ribbon)) {
		Write-Output "Cant Find Ribbon."
        New-Item $Ribbon 
    }
Write-Output "Found Ribbon"

#Show ribbon in File Explorer 
Write-Output "Remove search bar and only show icon"
Set-ItemProperty $Ribbon MinimizedStateTabletModeOff -Value 0
Set-ItemProperty $Ribbon MinimizedStateTabletModeOn -Value 0

#Checking for ContentDeliveryManager
Write-Output "Checking for ContentDeliveryManager"
$ContentDeliveryManager = "Registry::HKU\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\"
    If (!(Test-Path $ContentDeliveryManager)) {
		Write-Output "Cant Find ContentDeliveryManager."
        New-Item $ContentDeliveryManager 
    }
Write-Output "Found ContentDeliveryManager"
#prevents Default the apps from redownloading. 
Write-Output "prevents Default the apps from redownloading"
Set-ItemProperty $ContentDeliveryManager SystemPaneSuggestionsEnabled -Value 0
Set-ItemProperty $ContentDeliveryManager PreInstalledAppsEnabled -Value 0
Set-ItemProperty $ContentDeliveryManager OemPreInstalledAppsEnabled -Value 0

Write-Host "Sleeping for 20 seconds..." 
sleep -Seconds 20

#Unload the Default User Profile NTUSER.DAT file
Write-Host "Unloading Default user hive..." 
$unloaded = $false
$attempts = 0
while (!$unloaded -and ($attempts -le 5))
{
	[gc]::Collect() # necessary call to be able to unload registry hive
	REG UNLOAD HKU\Default
	$unloaded = $?
	$attempts += 1
}
if (!$unloaded)
{
	Write-Warning "Unable to dismount default user registry hive at HKU\DEFAULT!" 
}
Write-Host "Removing PS Drive..." 
Remove-PSDrive -Name HKU

#Loads the Software Hive
Write-Output "Loads the Software Hive"
reg load HKLM\Default_software $OSDisk\Windows\System32\config\software

#Checking for Explorer
Write-Output "Checking for ContentDeliveryManager"
$Explorer = "Registry::HKLM\Default_software\Microsoft\Windows\CurrentVersion\Explorer\"
    If (!(Test-Path $Explorer)) {
		Write-Output "Cant Find Explorer."
        New-Item $Explorer 
    }
Write-Output "Found Explorer"
#Disable Edge desktop shortcut
Write-Output "Disable Edge desktop shortcut"
Set-ItemProperty $Explorer DisableEdgeDesktopShortcutCreation -Value 1

#Checking for Microsoft
Write-Output "Checking for ContentDeliveryManager"
$Microsoft = "Registry::HKLM\Default_software\Policies\Microsoft\"
    If (!(Test-Path $Microsoft)) {
		Write-Output "Cant Find Microsoft."
        New-Item $Microsoft 
    }
Write-Output "Found Microsoft"

#Disable Edge autorun on Frist logon
Write-Output "Disable Edge autorun on Frist logon"
Set-ItemProperty $Microsoft PreventFirstRunPage -Value 1

#Checking for Microsoft
Write-Output "Checking for System"
$System = "Registry::HKLM\Default_software\Policies\Microsoft\Windows\System\"
    If (!(Test-Path $System)) {
		Write-Output "Cant Find System."
        New-Item $System 
    }
Write-Output "Found System"

#Disable Acrylic Blur Effect on Sign-in Screen
Write-Output "Disable Acrylic Blur Effect on Sign-in Screen"
Set-ItemProperty $System DisableAcrylicBackgroundOnLogon -Value 1

#Checking for AdvertisingInfo
Write-Output "Checking for AdvertisingInfo"
$AdvertisingInfo = "Registry::HKLM\Default_software\Microsoft\Windows\CurrentVersion\AdvertisingInfo\"
    If (!(Test-Path $AdvertisingInfo)) {
		Write-Output "Cant Find AdvertisingInfo."
        New-Item $AdvertisingInfo 
    }
Write-Output "Found AdvertisingInfo"

#Disabling Windows Feedback Experience program
Write-Output "Disabling Windows Feedback Experience program"
Set-ItemProperty $AdvertisingInfo Enabled -Value 0

#Checking for CloudContent
Write-Output "Checking for CloudContent"
$CloudContent = "Registry::HKLM\Default_software\Policies\Microsoft\Windows\CloudContent\"
    If (!(Test-Path $CloudContent)) {
		Write-Output "Cant Find CloudContent."
        New-Item $CloudContent 
    }
Write-Output "Found CloudContent"

#Disabling Windows Feedback Experience program
Write-Output "Adding Registry key to prevent bloatware apps from returning"
Set-ItemProperty $CloudContent DisableWindowsConsumerFeatures -Value 1

#Checking for DataCollection
Write-Output "Checking for DataCollection"
$DataCollection = "Registry::HKLM\Default_software\Microsoft\Windows\CurrentVersion\Policies\DataCollection\"
    If (!(Test-Path $DataCollection)) {
		Write-Output "Cant Find DataCollection."
        New-Item $DataCollection 
    }
Write-Output "Found DataCollection"

#Turns off Data Collection via the AllowTelemtry key by changing it to 0
Write-Output "Turns off Data Collection via the AllowTelemtry key by changing it to 0"
Set-ItemProperty $DataCollection AllowTelemetry -Value 0

Write-Host "Sleeping for 20 seconds..." 
sleep -Seconds 20

#Unload the Software Hive
reg unload HKLM\Default_software

Write-Output "Finished all tasks."

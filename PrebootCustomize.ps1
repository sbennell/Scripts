#Powershell script to customize windows Before Frist boot
#Version 2020.4
#Stewart Bennell 24/05/2020
#

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$OSDisk = "$($tsenv.Value("OSDisk"))"

#Loads the Default User Profile NTUSER.DAT file
Write-Output "Loads the Default User Profile NTUSER.DAT file"
reg load HKU\Default_User %OSDisk%\users\default\ntuser.dat

#Show This PC on Desktop
Write-Output "Show This PC on Desktop"
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0

#Show User Files on Desktop
Write-Output "Show User Files on Desktop"
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0

#Show Network Icon on Desktop
Write-Output "Show User Files on Desktop"
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0

#Disable Autoplay for all media and devices
Write-Output "Disable Autoplay for all media and devices"
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value 1

#Remove search bar and only show icon
Write-Output "Remove search bar and only show icon"
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 1

#Disables People icon on Taskbar
Write-Output "Disables People icon on Taskbar"
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People -Name PeopleBand -Value 0

#Disables Cortana Buttion
Write-Output "Disables Cortana Buttion"
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowCortanaButton -Value 0

#Turn Off Automatically Restart Apps After Sign-In 
Write-Output "Turn Off Automatically Restart Apps After Sign-In"
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon -Name RestartApps -Value 0

#Set Default Folder When Opening Explorer to This PC
Write-Output "Set Default Folder When Opening Explorer to This PC"
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

#Show ribbon in File Explorer when Table Mode is off
Write-Output "Show ribbon in File Explorer when Table Mode is off"
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon -Name MinimizedStateTabletModeOff -Value 0

#Show ribbon in File Explorer when Table Mode is on
Write-Output "Show ribbon in File Explorer when Table Mode is on"
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon -Name MinimizedStateTabletModeOn  -Value 0

#Show known file extensions
Write-Output "Show known file extensions"
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

#prevents Default the apps from redownloading. 
Write-Output "prevents Default the apps from redownloading"
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SystemPaneSuggestionsEnabled -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name PreInstalledAppsEnabled -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name OemPreInstalledAppsEnabled -Value 0


#Unload the Default User Profile NTUSER.DAT file
Write-Output "Unload the Default User Profile NTUSER.DAT file"
reg unload HKU\Default_User

#Loads the Software Hive
Write-Output "Loads the Software Hive"
reg load HKLM\Default_software %OSDisk%\Windows\System32\config\software

#Disable Edge desktop shortcut
Write-Output "Disable Edge desktop shortcut"
Set-ItemProperty -Path Registry::HKLM\Default_software\Microsoft\Windows\CurrentVersion\Explorer -Name DisableEdgeDesktopShortcutCreation -Value 1

#Disable Edge autorun on Frist logon
Write-Output "Disable Edge autorun on Frist logon"
Set-ItemProperty -Path Registry::HKLM\Default_software\Policies\Microsoft -Name PreventFirstRunPage -Value 1

#Disable Acrylic Blur Effect on Sign-in Screen
Write-Output "Disable Acrylic Blur Effect on Sign-in Screen"
Set-ItemProperty -Path Registry::HKLM\Default_software\Policies\Microsoft\Windows\System -Name DisableAcrylicBackgroundOnLogon -Value 1

#Disabling Windows Feedback Experience program
Write-Output "Disabling Windows Feedback Experience program"
Set-ItemProperty -Path Registry::HKLM\Default_software\Microsoft\Windows\CurrentVersion\AdvertisingInfo -Name Enabled -Value 0

#Disabling Windows Feedback Experience program
Write-Output "Adding Registry key to prevent bloatware apps from returning"
Set-ItemProperty -Path Registry::HKLM\Default_software\Policies\Microsoft\Windows\CloudContent -Name DisableWindowsConsumerFeatures -Value 1

#Turns off Data Collection via the AllowTelemtry key by changing it to 0
Write-Output "Turns off Data Collection via the AllowTelemtry key by changing it to 0"
Set-ItemProperty -Path Registry::HKLM\Default_software\Microsoft\Windows\CurrentVersion\Policies\DataCollection -Name AllowTelemetry -Value 1

#Unload the Software Hive
reg unload HKU\Default_User

Write-Output "Finished all tasks."

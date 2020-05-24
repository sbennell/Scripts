#Powershell script to customize windows Before Frist boot
#Version 2020.1
#Stewart Bennell 24/05/2020
#

#Loads the Default User Profile NTUSER.DAT file
reg load HKU\Default_User %OSDisk%\Users\Default\NTUSER.DAT

#Show This PC on Desktop
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0

#Show User Files on Desktop
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0

#Show Network Icon on Desktop
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0

#Disable Autoplay for all media and devices
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers -Name DisableAutoplay -Value 1

#Remove search bar and only show icon
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 1

#Remove Cortana Buttion
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowCortanaButton -Value 0

#Turn Off Automatically Restart Apps After Sign-In 
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon -Name RestartApps -Value 0

#Set Default Folder When Opening Explorer to This PC
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

#Show ribbon in File Explorer Table Mode off
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon -Name MinimizedStateTabletModeOff -Value 0

#Show ribbon in File Explorer Table Mode on
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon -Name MinimizedStateTabletModeOn  -Value 0

#Show known file extensions
Set-ItemProperty -Path Registry::HKU\Default_User\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

#prevents Default the apps from redownloading. 
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SystemPaneSuggestionsEnabled -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name PreInstalledAppsEnabled -Value 0
Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name OemPreInstalledAppsEnabled -Value 0


#Unload the Default User Profile NTUSER.DAT file
reg unload HKU\Default_User

#Loads the Software Hive
reg load HKLM\Default_software %OSDisk%\Windows\System32\config\software

#Add Shift + Right Click "Run as different user" Context Menu
#Look in to

#Disable Edge desktop shortcut
Set-ItemProperty -Path Registry::HKLM\Default_software\Microsoft\Windows\CurrentVersion\Explorer -Name DisableEdgeDesktopShortcutCreation -Value 1

#Disable Edge autorun on Frist logon
Set-ItemProperty -Path Registry::HKLM\Default_software\Policies\Microsoft -Name PreventFirstRunPage -Value 1

#Disable Acrylic Blur Effect on Sign-in Screen
Set-ItemProperty -Path Registry::HKLM\Default_software\Policies\Microsoft\Windows\System -Name DisableAcrylicBackgroundOnLogon -Value 1

#Unload the Software Hive
reg unload HKU\Default_User

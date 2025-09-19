<#
.SYNOPSIS
    Displays a toast notification reminding users to reboot.
.NOTES
    NAME: Remediate-RebootRequiredToast.ps1
    VERSION: 1.1
    AUTHOR: Stewart Bennell
#>

[CmdletBinding()]
param ()

#region Functions
function Show-ToastNotification {
    param (
        [System.Xml.XmlDocument] $Toast
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $ToastXML = New-Object -TypeName "Windows.Data.Xml.Dom.XmlDocument"
    $ToastXML.LoadXml($Toast.OuterXml)

    try {
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXML)
    }
    catch {
        Write-Warning "Failed to display the toast notification. Ensure the script is running as the logged-on user."
    }
}
#endregion

#region Register AppID for Action Center
$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
$App     = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"

if (-not (Test-Path -Path "$RegPath\$App")) {
    New-Item -Path "$RegPath\$App" -Force | Out-Null
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' | Out-Null
}

if ((Get-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne 1) {
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force | Out-Null
}
#endregion

#region Toast Notification XML
$Scenario        = "reminder"
$AttributionText = "System Alerts"
$HeaderText      = "Reboot Required"
$TitleText       = "Your system has been running for 14+ days"
$BodyText        = "Please save your work and reboot to ensure optimal performance."
$DismissButton   = "Later"

[System.Xml.XmlDocument]$Toast = @"
<toast scenario="$Scenario" duration="long">
    <visual>
        <binding template="ToastGeneric">
            <text placement="attribution">$AttributionText</text>
            <text>$HeaderText</text>
            <group>
                <subgroup>
                    <text hint-style="title" hint-wrap="true">$TitleText</text>
                    <text hint-style="body" hint-wrap="true">$BodyText</text>
                </subgroup>
            </group>
            <image placement="appLogoOverride" src="C:\Windows\System32\shell32.dll,-154" hint-crop="circle"/>
        </binding>
    </visual>
    <actions>
        <action activationType="protocol" arguments="shutdown.exe /r /t 0" content="Reboot Now"/>
        <action activationType="system" arguments="dismiss" content="$DismissButton"/>
    </actions>
    <audio src="ms-winsoundevent:Notification.Reminder"/>
</toast>
"@
#endregion

# Show the toast
Show-ToastNotification -Toast $Toast

# Exit 1 to indicate remediation ran (optional)
exit 1

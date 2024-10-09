# // ***************************************************************************
# // 
# // Copyright (c) Stewart Bennell. All rights reserved.
# // 
# // Microsoft Deployment Toolkit Powershell Scripts
# //
# // File:      mdtOptions.ps1
# // 
# // Version:   09.10.24-05
# //
# // Version History
# // 25.01.24-01: Initial version
# // 26.12.21-01:	Able to set Organisation and Set Recovery 
# // 26.12.21-02:	Add Variable Textbox to set one Custom Variable
# // 30.12.21-02:	Add Temporarily close the TS progress UI
# // 21.12.22-01:   Remove Set Recovery
# // 10.10.24-01:   Added HWID Activation Checkbox
# // 10.10.24-03:   Added logging
# // 10.10.24-04:   Added Windows Updates Checkbox
# // 10.10.24-05:   Aligned HWID Activation and DONE  Version text.
# // 
# // Purpose:   Running Windows updates During Deployment.
# // 
# // ***************************************************************************

# MDT environment setup
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$DeployShare = $TSEnv.Value("DeployRoot")
$OSDComputerName = $TSEnv.Value("OSDComputerName")

$logFile = "$DeployShare\Logs\$($OSDComputerName)\MDToptions.log"

# Ensure log directory exists
if (-not (Test-Path -Path (Split-Path $logFile))) {
    New-Item -ItemType Directory -Path (Split-Path $logFile) -Force
}

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path "$logFile" -Value "$timestamp - $message"
}

# Temporarily close the TS progress UI
$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(341,200)  # Adjusted height for layout
$Form.text                       = "Setting Options"
$Form.TopMost                    = $false

$SetOrganisation                 = New-Object system.Windows.Forms.ComboBox
$SetOrganisation.text            = "BENNELL IT"
$SetOrganisation.width           = 224
$SetOrganisation.height          = 20
@('Bennell IT','SOE','None') | ForEach-Object {[void] $SetOrganisation.Items.Add($_)}
$SetOrganisation.location        = New-Object System.Drawing.Point(105,50)
$SetOrganisation.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Organisation                    = New-Object system.Windows.Forms.Label
$Organisation.text               = "Organisation"
$Organisation.AutoSize           = $true
$Organisation.width              = 25
$Organisation.height             = 10
$Organisation.location           = New-Object System.Drawing.Point(14,50)
$Organisation.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

# Adding HWID Activation Checkbox
$HWIDActivationCheckbox          = New-Object System.Windows.Forms.CheckBox
$HWIDActivationCheckbox.text     = "HWID Activation"
$HWIDActivationCheckbox.AutoSize  = $true
$HWIDActivationCheckbox.location  = New-Object System.Drawing.Point(14,87)  # Updated location for the HWID checkbox
$HWIDActivationCheckbox.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

# Adding Windows Updates Checkbox next to HWID
$WindowsUpdatesCheckbox          = New-Object System.Windows.Forms.CheckBox
$WindowsUpdatesCheckbox.text     = "Windows Updates"
$WindowsUpdatesCheckbox.AutoSize  = $true
$WindowsUpdatesCheckbox.location  = New-Object System.Drawing.Point(150,87)  # Moved next to the HWID checkbox
$WindowsUpdatesCheckbox.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$WindowsUpdatesCheckbox.Checked   = $true  # Set default to checked

$Variable                        = New-Object system.Windows.Forms.Label
$Variable.text                   = "Variable"
$Variable.AutoSize               = $true
$Variable.width                  = 25
$Variable.height                 = 10
$Variable.location               = New-Object System.Drawing.Point(14,120)  # Adjusted position
$Variable.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SetVariable                     = New-Object System.Windows.Forms.TextBox
$SetVariable.multiline           = $false
$SetVariable.width               = 226
$SetVariable.height              = 20
$SetVariable.location            = New-Object System.Drawing.Point(104,120)
$SetVariable.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Header                          = New-Object system.Windows.Forms.Label
$Header.text                     = "Set Imaging Options"
$Header.AutoSize                 = $true
$Header.width                    = 25
$Header.height                   = 10
$Header.location                 = New-Object System.Drawing.Point(49,8)
$Header.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',20,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

# Updated Version label
$Version                         = New-Object system.Windows.Forms.Label
$Version.text                    = "Version:09.10.24-05"  # Updated version here
$Version.AutoSize                = $true
$Version.width                   = 25
$Version.height                  = 10
$Version.location                = New-Object System.Drawing.Point(15,160)  # Adjusted position for version
$Version.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

# Align DONE button next to Version text on the right
$Done                            = New-Object system.Windows.Forms.Button
$Done.text                       = "DONE"
$Done.width                      = 60
$Done.height                     = 30
$Done.visible                    = $true
$Done.location                   = New-Object System.Drawing.Point(250,155)  # Updated location next to Version
$Done.Font                       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Form.controls.AddRange(@($SetOrganisation,$Organisation,$HWIDActivationCheckbox,$WindowsUpdatesCheckbox,$Variable,$SetVariable,$Header,$Version,$Done))

$Done.Add_Click({ Set-Settings })

Function Set-Settings 
{	
	# Set organisation and log it
	$organisation = $SetOrganisation.Text.ToUpper()
	$TSEnv.Value("organisation") = "$($organisation)"
	Log-Message "Organisation set to: $organisation"
	
	# Set Option1 variable and log it
	$Option1 = $SetVariable.Text.ToUpper()
	$TSEnv.Value("Option1") = "$($Option1)"
	Log-Message "Option1 set to: $Option1"
	
	# Set HWID Activation based on the checkbox state and log it
	$HWIDActivation = $HWIDActivationCheckbox.Checked
	$TSEnv.Value("HWIDActivation") = "$($HWIDActivation)"
	Log-Message "HWID Activation set to: $HWIDActivation"
	
	# Set Windows Updates based on the checkbox state and log it
	$WindowsUpdates = $WindowsUpdatesCheckbox.Checked
	$TSEnv.Value("WindowsUpdates") = "$($WindowsUpdates)"
	Log-Message "Windows Updates set to: $WindowsUpdates"
	
	# Log done button clicked
	Log-Message "Settings completed. Closing the form."
	
	$Form.Close()
}

[void]$Form.ShowDialog()

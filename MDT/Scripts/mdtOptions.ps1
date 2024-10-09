<# 
	MDT Custom Variable
    Stewart Bennell 26/06/2021
	
	Version History
	26.12.21-01:	Able to set Organisation and Set Recovery 
	26.12.21-02:	Add Variable Textbox to set one Custom Variable
	30.12.21-02:	add Temporarily close the TS progress UI
	21.12.22-01:    Remove Set Recovery
	10.10.24-01:    Added HWID Activation Checkbox
#>

# Temporarily close the TS progress UI
$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(341,230)  # Increased height to accommodate checkbox
$Form.text                       = "Setting Options"
$Form.TopMost                    = $false

$Done                            = New-Object system.Windows.Forms.Button
$Done.text                       = "DONE"
$Done.width                      = 60
$Done.height                     = 30
$Done.visible                    = $true
$Done.location                   = New-Object System.Drawing.Point(268,180)  # Updated location
$Done.Font                       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

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

# Adding HWID Activation Checkbox (moved to where Recovery was)
$HWIDActivationCheckbox          = New-Object System.Windows.Forms.CheckBox
$HWIDActivationCheckbox.text     = "HWID Activation"
$HWIDActivationCheckbox.AutoSize  = $true
$HWIDActivationCheckbox.location  = New-Object System.Drawing.Point(14,87)  # Updated location for the checkbox
$HWIDActivationCheckbox.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Variable                        = New-Object system.Windows.Forms.Label
$Variable.text                   = "Variable"
$Variable.AutoSize               = $true
$Variable.width                  = 25
$Variable.height                 = 10
$Variable.location               = New-Object System.Drawing.Point(14,120)
$Variable.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SetVariable                     = New-Object system.Windows.Forms.TextBox
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

$Version                         = New-Object system.Windows.Forms.Label
$Version.text                    = "Version:21.12.22-01"
$Version.AutoSize                = $true
$Version.width                   = 25
$Version.height                  = 10
$Version.location                = New-Object System.Drawing.Point(15,160)
$Version.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Form.controls.AddRange(@($Done,$SetOrganisation,$Organisation,$HWIDActivationCheckbox,$Variable,$SetVariable,$Header,$Version))

$Done.Add_Click({ Set-Settings })

Function Set-Settings 
{	
	$organisation = $SetOrganisation.Text.ToUpper()
	$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
	$TSEnv.Value("organisation") = "$($organisation)"
	Write-Host  $organisation
	
	$Option1 = $SetVariable.Text.ToUpper()
	$TSEnv.Value("Option1") = "$($Option1)"
	Write-Host  $Option1
	
	# Set HWID Activation value based on the checkbox state
	$HWIDActivation = $HWIDActivationCheckbox.Checked
	$TSEnv.Value("HWIDActivation") = "$($HWIDActivation)"
	Write-Host "HWID Activation set to: $HWIDActivation"
	
	$Form.Close()
}

[void]$Form.ShowDialog()

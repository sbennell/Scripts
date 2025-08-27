# Windows Autopilot Info GUI - All Options in One Tab
# Requires PowerShell 5.1 or later with Windows Forms

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Autopilot Info Tool"
$form.Size = New-Object System.Drawing.Size(750, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Create main panel for scrolling
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Location = New-Object System.Drawing.Point(10, 10)
$mainPanel.Size = New-Object System.Drawing.Size(715, 390)
$mainPanel.AutoScroll = $true

# Output mode radio buttons
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Location = New-Object System.Drawing.Point(10, 10)
$groupBox.Size = New-Object System.Drawing.Size(700, 70)
$groupBox.Text = "Output Mode"

$radioUpload = New-Object System.Windows.Forms.RadioButton
$radioUpload.Location = New-Object System.Drawing.Point(10, 20)
$radioUpload.Size = New-Object System.Drawing.Size(200, 20)
$radioUpload.Text = "Upload to Autopilot (-Online)"
$radioUpload.Checked = $true

$radioSaveFile = New-Object System.Windows.Forms.RadioButton
$radioSaveFile.Location = New-Object System.Drawing.Point(10, 45)
$radioSaveFile.Size = New-Object System.Drawing.Size(120, 20)
$radioSaveFile.Text = "Save to CSV file:"

$textFilePath = New-Object System.Windows.Forms.TextBox
$textFilePath.Location = New-Object System.Drawing.Point(140, 43)
$textFilePath.Size = New-Object System.Drawing.Size(350, 20)
$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$textFilePath.Text = Join-Path $documentsPath "AutopilotInfo.csv"
$textFilePath.Enabled = $false

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Location = New-Object System.Drawing.Point(500, 42)
$btnBrowse.Size = New-Object System.Drawing.Size(75, 23)
$btnBrowse.Text = "Browse..."
$btnBrowse.Enabled = $false

$checkAppend = New-Object System.Windows.Forms.CheckBox
$checkAppend.Location = New-Object System.Drawing.Point(590, 45)
$checkAppend.Size = New-Object System.Drawing.Size(80, 20)
$checkAppend.Text = "Append"
$checkAppend.Enabled = $false

# Add radio buttons and file controls to the group box
$groupBox.Controls.AddRange(@($radioUpload, $radioSaveFile, $textFilePath, $btnBrowse, $checkAppend))

# Group Tag section
$lblGroupTag = New-Object System.Windows.Forms.Label
$lblGroupTag.Location = New-Object System.Drawing.Point(20, 90)
$lblGroupTag.Size = New-Object System.Drawing.Size(70, 20)
$lblGroupTag.Text = "Group Tag:"

# Site dropdown
$lblSite = New-Object System.Windows.Forms.Label
$lblSite.Location = New-Object System.Drawing.Point(150, 90)
$lblSite.Size = New-Object System.Drawing.Size(30, 20)
$lblSite.Text = "Site:"

$comboSite = New-Object System.Windows.Forms.ComboBox
$comboSite.Location = New-Object System.Drawing.Point(185, 88)
$comboSite.Size = New-Object System.Drawing.Size(80, 20)
$comboSite.DropDownStyle = "DropDownList"
$comboSite.Items.AddRange(@("MT", "SJW", "Custom"))
$comboSite.SelectedIndex = 0

# Custom site textbox (initially hidden)
$textCustomSite = New-Object System.Windows.Forms.TextBox
$textCustomSite.Location = New-Object System.Drawing.Point(275, 88)
$textCustomSite.Size = New-Object System.Drawing.Size(60, 20)
$textCustomSite.Visible = $false

# Type dropdown
$lblType = New-Object System.Windows.Forms.Label
$lblType.Location = New-Object System.Drawing.Point(345, 90)
$lblType.Size = New-Object System.Drawing.Size(35, 20)
$lblType.Text = "Type:"

$comboType = New-Object System.Windows.Forms.ComboBox
$comboType.Location = New-Object System.Drawing.Point(385, 88)
$comboType.Size = New-Object System.Drawing.Size(80, 20)
$comboType.DropDownStyle = "DropDownList"
$comboType.Items.AddRange(@(
"STU", "STF", "SHARE"))
$comboType.SelectedIndex = 0

# Custom suffix textbox
$lblCustom = New-Object System.Windows.Forms.Label
$lblCustom.Location = New-Object System.Drawing.Point(475, 90)
$lblCustom.Size = New-Object System.Drawing.Size(50, 20)
$lblCustom.Text = "Custom:"

$textCustomSuffix = New-Object System.Windows.Forms.TextBox
$textCustomSuffix.Location = New-Object System.Drawing.Point(530, 88)
$textCustomSuffix.Size = New-Object System.Drawing.Size(80, 20)
$textCustomSuffix.PlaceholderText = "xxxx"

# Generated Group Tag display (read-only)
$lblGeneratedTag = New-Object System.Windows.Forms.Label
$lblGeneratedTag.Location = New-Object System.Drawing.Point(150, 115)
$lblGeneratedTag.Size = New-Object System.Drawing.Size(80, 20)
$lblGeneratedTag.Text = "Generated:"

$textGroupTag = New-Object System.Windows.Forms.TextBox
$textGroupTag.Location = New-Object System.Drawing.Point(235, 113)
$textGroupTag.Size = New-Object System.Drawing.Size(250, 20)
$textGroupTag.ReadOnly = $true
$textGroupTag.BackColor = [System.Drawing.Color]::LightGray

# Assigned User section
$lblAssignedUser = New-Object System.Windows.Forms.Label
$lblAssignedUser.Location = New-Object System.Drawing.Point(20, 145)
$lblAssignedUser.Size = New-Object System.Drawing.Size(120, 20)
$lblAssignedUser.Text = "Assigned User:"

$textAssignedUser = New-Object System.Windows.Forms.TextBox
$textAssignedUser.Location = New-Object System.Drawing.Point(150, 143)
$textAssignedUser.Size = New-Object System.Drawing.Size(300, 20)

$lblUserHelp = New-Object System.Windows.Forms.Label
$lblUserHelp.Location = New-Object System.Drawing.Point(460, 145)
$lblUserHelp.Size = New-Object System.Drawing.Size(150, 20)
$lblUserHelp.Text = "(user@domain.com)"
$lblUserHelp.ForeColor = [System.Drawing.Color]::Gray

# Assigned Computer Name section
$lblAssignedComputerName = New-Object System.Windows.Forms.Label
$lblAssignedComputerName.Location = New-Object System.Drawing.Point(20, 175)
$lblAssignedComputerName.Size = New-Object System.Drawing.Size(120, 20)
$lblAssignedComputerName.Text = "Assigned Computer Name:"

$textAssignedComputerName = New-Object System.Windows.Forms.TextBox
$textAssignedComputerName.Location = New-Object System.Drawing.Point(150, 173)
$textAssignedComputerName.Size = New-Object System.Drawing.Size(300, 20)
$textAssignedComputerName.Enabled = $true

$lblComputerNameHelp = New-Object System.Windows.Forms.Label
$lblComputerNameHelp.Location = New-Object System.Drawing.Point(460, 175)
$lblComputerNameHelp.Size = New-Object System.Drawing.Size(150, 20)
$lblComputerNameHelp.Text = "(AAD join only)"
$lblComputerNameHelp.ForeColor = [System.Drawing.Color]::Gray

# Action checkboxes
$checkAssign = New-Object System.Windows.Forms.CheckBox
$checkAssign.Location = New-Object System.Drawing.Point(20, 205)
$checkAssign.Size = New-Object System.Drawing.Size(200, 20)
$checkAssign.Text = "Wait for assignment (-Assign)"
$checkAssign.Enabled = $true

$checkReboot = New-Object System.Windows.Forms.CheckBox
$checkReboot.Location = New-Object System.Drawing.Point(240, 205)
$checkReboot.Size = New-Object System.Drawing.Size(200, 20)
$checkReboot.Text = "Reboot after assignment (-Reboot)"
$checkReboot.Enabled = $true

$lblOnlineHelp = New-Object System.Windows.Forms.Label
$lblOnlineHelp.Location = New-Object System.Drawing.Point(450, 205)
$lblOnlineHelp.Size = New-Object System.Drawing.Size(150, 20)
$lblOnlineHelp.Text = "(Upload mode only)"
$lblOnlineHelp.ForeColor = [System.Drawing.Color]::Gray

# Add all controls to main panel
$mainPanel.Controls.AddRange(@(
    $groupBox,
    $lblGroupTag, $lblSite, $comboSite, $textCustomSite, $lblType, $comboType, $lblCustom, $textCustomSuffix, $lblGeneratedTag, $textGroupTag,
    $lblAssignedUser, $textAssignedUser, $lblUserHelp,
    $lblAssignedComputerName, $textAssignedComputerName, $lblComputerNameHelp,
    $checkAssign, $checkReboot, $lblOnlineHelp
))

# Status label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(20, 415)
$lblStatus.Size = New-Object System.Drawing.Size(700, 20)
$lblStatus.Text = "Ready to retrieve Autopilot information"
$lblStatus.ForeColor = [System.Drawing.Color]::Blue

# Output textbox
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(20, 445)
$txtOutput.Size = New-Object System.Drawing.Size(700, 160)
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object System.Drawing.Font("Consolas", 9)

# Buttons
$btnGetInfo = New-Object System.Windows.Forms.Button
$btnGetInfo.Location = New-Object System.Drawing.Point(20, 620)
$btnGetInfo.Size = New-Object System.Drawing.Size(120, 30)
$btnGetInfo.Text = "Get Autopilot Info"
$btnGetInfo.BackColor = [System.Drawing.Color]::LightGreen

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Location = New-Object System.Drawing.Point(160, 620)
$btnClear.Size = New-Object System.Drawing.Size(80, 30)
$btnClear.Text = "Clear"

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Location = New-Object System.Drawing.Point(640, 620)
$btnExit.Size = New-Object System.Drawing.Size(80, 30)
$btnExit.Text = "Exit"

# Event handlers
$radioSaveFile.Add_CheckedChanged({
    $textFilePath.Enabled = $radioSaveFile.Checked
    $btnBrowse.Enabled = $radioSaveFile.Checked
    $checkAppend.Enabled = $radioSaveFile.Checked
})

# Function to update the generated group tag
function Update-GroupTag {
    $site = if ($comboSite.SelectedItem -eq "Custom") { $textCustomSite.Text.Trim() } else { $comboSite.SelectedItem }
    $type = $comboType.SelectedItem
    $custom = $textCustomSuffix.Text.Trim()
    
    if ($site -and $type) {
        if ($custom) {
            $textGroupTag.Text = "$site-WIN-AP-$type-$custom"
        } else {
            $textGroupTag.Text = "$site-WIN-AP-$type"
        }
    } else {
        $textGroupTag.Text = ""
    }
}

# Site dropdown change event
$comboSite.Add_SelectedIndexChanged({
    if ($comboSite.SelectedItem -eq "Custom") {
        $textCustomSite.Visible = $true
    } else {
        $textCustomSite.Visible = $false
        $textCustomSite.Text = ""
    }
    Update-GroupTag
})

# Custom site text change event
$textCustomSite.Add_TextChanged({
    Update-GroupTag
})

# Type dropdown change event
$comboType.Add_SelectedIndexChanged({
    Update-GroupTag
})

# Custom suffix text change event
$textCustomSuffix.Add_TextChanged({
    Update-GroupTag
})

$radioUpload.Add_CheckedChanged({
    # Enable/disable online-specific options
    $textAssignedComputerName.Enabled = $radioUpload.Checked
    $checkAssign.Enabled = $radioUpload.Checked
    $checkReboot.Enabled = $radioUpload.Checked
    
    if (-not $radioUpload.Checked) {
        $textAssignedComputerName.Clear()
        $checkAssign.Checked = $false
        $checkReboot.Checked = $false
    }
})

$btnBrowse.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
    $saveDialog.Title = "Save Autopilot Info As"
    $saveDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
    $saveDialog.FileName = "AutopilotInfo.csv"
    
    if ($saveDialog.ShowDialog() -eq "OK") {
        $textFilePath.Text = $saveDialog.FileName
    }
})

$btnGetInfo.Add_Click({
    $lblStatus.Text = "Preparing to retrieve Autopilot information..."
    $lblStatus.ForeColor = [System.Drawing.Color]::Orange
    $txtOutput.Clear()
    $form.Refresh()
    
    try {
        # Set TLS 1.2
        $txtOutput.AppendText("Setting security protocol to TLS 1.2...`r`n")
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Set execution policy
        $txtOutput.AppendText("Setting execution policy...`r`n")
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
        
        # Check if script is already installed
        $scriptInstalled = $false
        try {
            $installedScript = Get-InstalledScript -Name "Get-WindowsAutopilotInfo" -ErrorAction SilentlyContinue
            if ($installedScript) {
                $txtOutput.AppendText("Get-WindowsAutopilotInfo script is already installed (Version: $($installedScript.Version))`r`n")
                $scriptInstalled = $true
            }
        } catch {
            # Script not installed
        }
        
        # Install script if not already installed
        if (-not $scriptInstalled) {
            $txtOutput.AppendText("Installing Get-WindowsAutopilotInfo script...`r`n")
            Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser
            $txtOutput.AppendText("Script installed successfully.`r`n")
        }
        
        # Build command parameters
        $params = @{}
        
        # Check which mode is selected
        if ($radioUpload.Checked) {
            # Online mode
            $params.Online = $true
            $txtOutput.AppendText("Mode: Upload to Autopilot service`r`n")
            
            if ($textAssignedComputerName.Text.Trim() -ne "") {
                $params.AssignedComputerName = $textAssignedComputerName.Text.Trim()
                $txtOutput.AppendText("Assigned computer name: $($params.AssignedComputerName)`r`n")
            }
            
            if ($checkAssign.Checked) {
                $params.Assign = $true
                $txtOutput.AppendText("Will wait for profile assignment`r`n")
            }
            
            if ($checkReboot.Checked) {
                $params.Reboot = $true
                $txtOutput.AppendText("Will reboot after assignment`r`n")
            }
        } else {
            # File output mode
            if ($textFilePath.Text.Trim() -ne "") {
                $outputPath = $textFilePath.Text
                
                # Validate and create directory if needed
                $directory = Split-Path $outputPath -Parent
                if (-not (Test-Path $directory)) {
                    $txtOutput.AppendText("Creating directory: $directory`r`n")
                    try {
                        New-Item -ItemType Directory -Path $directory -Force | Out-Null
                    } catch {
                        throw "Failed to create directory: $directory. Error: $($_.Exception.Message)"
                    }
                }
                
                # Test write permissions
                try {
                    $testFile = Join-Path $directory "test_write_$(Get-Random).tmp"
                    "test" | Out-File -FilePath $testFile -Force
                    Remove-Item $testFile -Force
                    $txtOutput.AppendText("Write permissions verified for: $directory`r`n")
                } catch {
                    throw "No write permissions for directory: $directory. Error: $($_.Exception.Message)"
                }
                
                $params.OutputFile = $outputPath
                $txtOutput.AppendText("Mode: Save to file - $outputPath`r`n")
                
                if ($checkAppend.Checked) {
                    $params.Append = $true
                    $txtOutput.AppendText("Will append to existing file`r`n")
                }
            } else {
                throw "Please specify a file path for CSV output"
            }
        }
        
        # Other parameters
        if ($textGroupTag.Text.Trim() -ne "") {
            $params.GroupTag = $textGroupTag.Text.Trim()
            $txtOutput.AppendText("Group tag: $($params.GroupTag)`r`n")
        }
        
        if ($textAssignedUser.Text.Trim() -ne "") {
            $params.AssignedUser = $textAssignedUser.Text.Trim()
            $txtOutput.AppendText("Assigned user: $($params.AssignedUser)`r`n")
        }
        
        $txtOutput.AppendText("`r`nRetrieving Windows Autopilot information...`r`n")
        $txtOutput.AppendText("=" * 60 + "`r`n")
        
        # Execute Get-WindowsAutopilotInfo
        if ($params.Count -gt 0) {
            $result = Get-WindowsAutopilotInfo @params 2>&1
        } else {
            $result = Get-WindowsAutopilotInfo 2>&1
        }
        
        # Display results
        if ($result) {
            $txtOutput.AppendText($result.ToString())
        }
        
        $txtOutput.AppendText("`r`n" + "=" * 60 + "`r`n")
        $txtOutput.AppendText("Operation completed successfully!`r`n")
        $lblStatus.Text = "Autopilot information retrieved successfully"
        $lblStatus.ForeColor = [System.Drawing.Color]::Green
        
    } catch {
        $errorMsg = $_.Exception.Message
        $txtOutput.AppendText("`r`nERROR: $errorMsg`r`n")
        $lblStatus.Text = "Error occurred while retrieving Autopilot information"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
})

$btnClear.Add_Click({
    $txtOutput.Clear()
    $lblStatus.Text = "Ready to retrieve Autopilot information"
    $lblStatus.ForeColor = [System.Drawing.Color]::Blue
})

$btnExit.Add_Click({
    $form.Close()
})

# Add all main controls to the form
$form.Controls.Add($mainPanel)
$form.Controls.Add($lblStatus)
$form.Controls.Add($txtOutput)
$form.Controls.Add($btnGetInfo)# Windows Autopilot Info GUI - All Options in One Tab
# Requires PowerShell 5.1 or later with Windows Forms

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Autopilot Info Tool"
$form.Size = New-Object System.Drawing.Size(750, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Create main panel for scrolling
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Location = New-Object System.Drawing.Point(10, 10)
$mainPanel.Size = New-Object System.Drawing.Size(715, 390)
$mainPanel.AutoScroll = $true

# Output mode radio buttons
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Location = New-Object System.Drawing.Point(10, 10)
$groupBox.Size = New-Object System.Drawing.Size(700, 70)
$groupBox.Text = "Output Mode"

$radioUpload = New-Object System.Windows.Forms.RadioButton
$radioUpload.Location = New-Object System.Drawing.Point(10, 20)
$radioUpload.Size = New-Object System.Drawing.Size(200, 20)
$radioUpload.Text = "Upload to Autopilot (-Online)"
$radioUpload.Checked = $true

$radioSaveFile = New-Object System.Windows.Forms.RadioButton
$radioSaveFile.Location = New-Object System.Drawing.Point(10, 45)
$radioSaveFile.Size = New-Object System.Drawing.Size(120, 20)
$radioSaveFile.Text = "Save to CSV file:"

$textFilePath = New-Object System.Windows.Forms.TextBox
$textFilePath.Location = New-Object System.Drawing.Point(140, 43)
$textFilePath.Size = New-Object System.Drawing.Size(350, 20)
$documentsPath = [Environment]::GetFolderPath("MyDocuments")
$textFilePath.Text = Join-Path $documentsPath "AutopilotInfo.csv"
$textFilePath.Enabled = $false

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Location = New-Object System.Drawing.Point(500, 42)
$btnBrowse.Size = New-Object System.Drawing.Size(75, 23)
$btnBrowse.Text = "Browse..."
$btnBrowse.Enabled = $false

$checkAppend = New-Object System.Windows.Forms.CheckBox
$checkAppend.Location = New-Object System.Drawing.Point(590, 45)
$checkAppend.Size = New-Object System.Drawing.Size(80, 20)
$checkAppend.Text = "Append"
$checkAppend.Enabled = $false

# Add radio buttons and file controls to the group box
$groupBox.Controls.AddRange(@($radioUpload, $radioSaveFile, $textFilePath, $btnBrowse, $checkAppend))

# Group Tag section
$lblGroupTag = New-Object System.Windows.Forms.Label
$lblGroupTag.Location = New-Object System.Drawing.Point(20, 90)
$lblGroupTag.Size = New-Object System.Drawing.Size(70, 20)
$lblGroupTag.Text = "Group Tag:"

# Site dropdown
$lblSite = New-Object System.Windows.Forms.Label
$lblSite.Location = New-Object System.Drawing.Point(150, 90)
$lblSite.Size = New-Object System.Drawing.Size(30, 20)
$lblSite.Text = "Site:"

$comboSite = New-Object System.Windows.Forms.ComboBox
$comboSite.Location = New-Object System.Drawing.Point(185, 88)
$comboSite.Size = New-Object System.Drawing.Size(80, 20)
$comboSite.DropDownStyle = "DropDownList"
$comboSite.Items.AddRange(@("MT", "SJW", "Custom"))
$comboSite.SelectedIndex = 0

# Custom site textbox (initially hidden)
$textCustomSite = New-Object System.Windows.Forms.TextBox
$textCustomSite.Location = New-Object System.Drawing.Point(275, 88)
$textCustomSite.Size = New-Object System.Drawing.Size(60, 20)
$textCustomSite.Visible = $false

# Type dropdown
$lblType = New-Object System.Windows.Forms.Label
$lblType.Location = New-Object System.Drawing.Point(345, 90)
$lblType.Size = New-Object System.Drawing.Size(35, 20)
$lblType.Text = "Type:"

$comboType = New-Object System.Windows.Forms.ComboBox
$comboType.Location = New-Object System.Drawing.Point(385, 88)
$comboType.Size = New-Object System.Drawing.Size(80, 20)
$comboType.DropDownStyle = "DropDownList"
$comboType.Items.AddRange(@(
"STU", "STF", "SHARE"))
$comboType.SelectedIndex = 0

# Custom suffix textbox
$lblCustom = New-Object System.Windows.Forms.Label
$lblCustom.Location = New-Object System.Drawing.Point(475, 90)
$lblCustom.Size = New-Object System.Drawing.Size(50, 20)
$lblCustom.Text = "Custom:"

$textCustomSuffix = New-Object System.Windows.Forms.TextBox
$textCustomSuffix.Location = New-Object System.Drawing.Point(530, 88)
$textCustomSuffix.Size = New-Object System.Drawing.Size(80, 20)
$textCustomSuffix.PlaceholderText = "xxxx"

# Generated Group Tag display (read-only)
$lblGeneratedTag = New-Object System.Windows.Forms.Label
$lblGeneratedTag.Location = New-Object System.Drawing.Point(150, 115)
$lblGeneratedTag.Size = New-Object System.Drawing.Size(80, 20)
$lblGeneratedTag.Text = "Generated:"

$textGroupTag = New-Object System.Windows.Forms.TextBox
$textGroupTag.Location = New-Object System.Drawing.Point(235, 113)
$textGroupTag.Size = New-Object System.Drawing.Size(250, 20)
$textGroupTag.ReadOnly = $true
$textGroupTag.BackColor = [System.Drawing.Color]::LightGray

# Assigned User section
$lblAssignedUser = New-Object System.Windows.Forms.Label
$lblAssignedUser.Location = New-Object System.Drawing.Point(20, 145)
$lblAssignedUser.Size = New-Object System.Drawing.Size(120, 20)
$lblAssignedUser.Text = "Assigned User:"

$textAssignedUser = New-Object System.Windows.Forms.TextBox
$textAssignedUser.Location = New-Object System.Drawing.Point(150, 143)
$textAssignedUser.Size = New-Object System.Drawing.Size(300, 20)

$lblUserHelp = New-Object System.Windows.Forms.Label
$lblUserHelp.Location = New-Object System.Drawing.Point(460, 145)
$lblUserHelp.Size = New-Object System.Drawing.Size(150, 20)
$lblUserHelp.Text = "(user@domain.com)"
$lblUserHelp.ForeColor = [System.Drawing.Color]::Gray

# Assigned Computer Name section
$lblAssignedComputerName = New-Object System.Windows.Forms.Label
$lblAssignedComputerName.Location = New-Object System.Drawing.Point(20, 175)
$lblAssignedComputerName.Size = New-Object System.Drawing.Size(120, 20)
$lblAssignedComputerName.Text = "Assigned Computer Name:"

$textAssignedComputerName = New-Object System.Windows.Forms.TextBox
$textAssignedComputerName.Location = New-Object System.Drawing.Point(150, 173)
$textAssignedComputerName.Size = New-Object System.Drawing.Size(300, 20)
$textAssignedComputerName.Enabled = $true

$lblComputerNameHelp = New-Object System.Windows.Forms.Label
$lblComputerNameHelp.Location = New-Object System.Drawing.Point(460, 175)
$lblComputerNameHelp.Size = New-Object System.Drawing.Size(150, 20)
$lblComputerNameHelp.Text = "(AAD join only)"
$lblComputerNameHelp.ForeColor = [System.Drawing.Color]::Gray

# Action checkboxes
$checkAssign = New-Object System.Windows.Forms.CheckBox
$checkAssign.Location = New-Object System.Drawing.Point(20, 205)
$checkAssign.Size = New-Object System.Drawing.Size(200, 20)
$checkAssign.Text = "Wait for assignment (-Assign)"
$checkAssign.Enabled = $true

$checkReboot = New-Object System.Windows.Forms.CheckBox
$checkReboot.Location = New-Object System.Drawing.Point(240, 205)
$checkReboot.Size = New-Object System.Drawing.Size(200, 20)
$checkReboot.Text = "Reboot after assignment (-Reboot)"
$checkReboot.Enabled = $true

$lblOnlineHelp = New-Object System.Windows.Forms.Label
$lblOnlineHelp.Location = New-Object System.Drawing.Point(450, 205)
$lblOnlineHelp.Size = New-Object System.Drawing.Size(150, 20)
$lblOnlineHelp.Text = "(Upload mode only)"
$lblOnlineHelp.ForeColor = [System.Drawing.Color]::Gray

# Add all controls to main panel
$mainPanel.Controls.AddRange(@(
    $groupBox,
    $lblGroupTag, $lblSite, $comboSite, $textCustomSite, $lblType, $comboType, $lblCustom, $textCustomSuffix, $lblGeneratedTag, $textGroupTag,
    $lblAssignedUser, $textAssignedUser, $lblUserHelp,
    $lblAssignedComputerName, $textAssignedComputerName, $lblComputerNameHelp,
    $checkAssign, $checkReboot, $lblOnlineHelp
))

# Status label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(20, 415)
$lblStatus.Size = New-Object System.Drawing.Size(700, 20)
$lblStatus.Text = "Ready to retrieve Autopilot information"
$lblStatus.ForeColor = [System.Drawing.Color]::Blue

# Output textbox
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(20, 445)
$txtOutput.Size = New-Object System.Drawing.Size(700, 160)
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object System.Drawing.Font("Consolas", 9)

# Buttons
$btnGetInfo = New-Object System.Windows.Forms.Button
$btnGetInfo.Location = New-Object System.Drawing.Point(20, 620)
$btnGetInfo.Size = New-Object System.Drawing.Size(120, 30)
$btnGetInfo.Text = "Get Autopilot Info"
$btnGetInfo.BackColor = [System.Drawing.Color]::LightGreen

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Location = New-Object System.Drawing.Point(160, 620)
$btnClear.Size = New-Object System.Drawing.Size(80, 30)
$btnClear.Text = "Clear"

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Location = New-Object System.Drawing.Point(640, 620)
$btnExit.Size = New-Object System.Drawing.Size(80, 30)
$btnExit.Text = "Exit"

# Event handlers
$radioSaveFile.Add_CheckedChanged({
    $textFilePath.Enabled = $radioSaveFile.Checked
    $btnBrowse.Enabled = $radioSaveFile.Checked
    $checkAppend.Enabled = $radioSaveFile.Checked
})

# Function to update the generated group tag
function Update-GroupTag {
    $site = if ($comboSite.SelectedItem -eq "Custom") { $textCustomSite.Text.Trim() } else { $comboSite.SelectedItem }
    $type = $comboType.SelectedItem
    $custom = $textCustomSuffix.Text.Trim()
    
    if ($site -and $type) {
        if ($custom) {
            $textGroupTag.Text = "$site-WIN-AP-$type-$custom"
        } else {
            $textGroupTag.Text = "$site-WIN-AP-$type"
        }
    } else {
        $textGroupTag.Text = ""
    }
}

# Site dropdown change event
$comboSite.Add_SelectedIndexChanged({
    if ($comboSite.SelectedItem -eq "Custom") {
        $textCustomSite.Visible = $true
    } else {
        $textCustomSite.Visible = $false
        $textCustomSite.Text = ""
    }
    Update-GroupTag
})

# Custom site text change event
$textCustomSite.Add_TextChanged({
    Update-GroupTag
})

# Type dropdown change event
$comboType.Add_SelectedIndexChanged({
    Update-GroupTag
})

# Custom suffix text change event
$textCustomSuffix.Add_TextChanged({
    Update-GroupTag
})

$radioUpload.Add_CheckedChanged({
    # Enable/disable online-specific options
    $textAssignedComputerName.Enabled = $radioUpload.Checked
    $checkAssign.Enabled = $radioUpload.Checked
    $checkReboot.Enabled = $radioUpload.Checked
    
    if (-not $radioUpload.Checked) {
        $textAssignedComputerName.Clear()
        $checkAssign.Checked = $false
        $checkReboot.Checked = $false
    }
})

$btnBrowse.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
    $saveDialog.Title = "Save Autopilot Info As"
    $saveDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
    $saveDialog.FileName = "AutopilotInfo.csv"
    
    if ($saveDialog.ShowDialog() -eq "OK") {
        $textFilePath.Text = $saveDialog.FileName
    }
})

$btnGetInfo.Add_Click({
    $lblStatus.Text = "Preparing to retrieve Autopilot information..."
    $lblStatus.ForeColor = [System.Drawing.Color]::Orange
    $txtOutput.Clear()
    $form.Refresh()
    
    try {
        # Set TLS 1.2
        $txtOutput.AppendText("Setting security protocol to TLS 1.2...`r`n")
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Set execution policy
        $txtOutput.AppendText("Setting execution policy...`r`n")
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
        
        # Check if script is already installed
        $scriptInstalled = $false
        try {
            $installedScript = Get-InstalledScript -Name "Get-WindowsAutopilotInfo" -ErrorAction SilentlyContinue
            if ($installedScript) {
                $txtOutput.AppendText("Get-WindowsAutopilotInfo script is already installed (Version: $($installedScript.Version))`r`n")
                $scriptInstalled = $true
            }
        } catch {
            # Script not installed
        }
        
        # Install script if not already installed
        if (-not $scriptInstalled) {
            $txtOutput.AppendText("Installing Get-WindowsAutopilotInfo script...`r`n")
            Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser
            $txtOutput.AppendText("Script installed successfully.`r`n")
        }
        
        # Build command parameters
        $params = @{}
        
        # Check which mode is selected
        if ($radioUpload.Checked) {
            # Online mode
            $params.Online = $true
            $txtOutput.AppendText("Mode: Upload to Autopilot service`r`n")
            
            if ($textAssignedComputerName.Text.Trim() -ne "") {
                $params.AssignedComputerName = $textAssignedComputerName.Text.Trim()
                $txtOutput.AppendText("Assigned computer name: $($params.AssignedComputerName)`r`n")
            }
            
            if ($checkAssign.Checked) {
                $params.Assign = $true
                $txtOutput.AppendText("Will wait for profile assignment`r`n")
            }
            
            if ($checkReboot.Checked) {
                $params.Reboot = $true
                $txtOutput.AppendText("Will reboot after assignment`r`n")
            }
        } else {
            # File output mode
            if ($textFilePath.Text.Trim() -ne "") {
                $outputPath = $textFilePath.Text
                
                # Validate and create directory if needed
                $directory = Split-Path $outputPath -Parent
                if (-not (Test-Path $directory)) {
                    $txtOutput.AppendText("Creating directory: $directory`r`n")
                    try {
                        New-Item -ItemType Directory -Path $directory -Force | Out-Null
                    } catch {
                        throw "Failed to create directory: $directory. Error: $($_.Exception.Message)"
                    }
                }
                
                # Test write permissions
                try {
                    $testFile = Join-Path $directory "test_write_$(Get-Random).tmp"
                    "test" | Out-File -FilePath $testFile -Force
                    Remove-Item $testFile -Force
                    $txtOutput.AppendText("Write permissions verified for: $directory`r`n")
                } catch {
                    throw "No write permissions for directory: $directory. Error: $($_.Exception.Message)"
                }
                
                $params.OutputFile = $outputPath
                $txtOutput.AppendText("Mode: Save to file - $outputPath`r`n")
                
                if ($checkAppend.Checked) {
                    $params.Append = $true
                    $txtOutput.AppendText("Will append to existing file`r`n")
                }
            } else {
                throw "Please specify a file path for CSV output"
            }
        }
        
        # Other parameters
        if ($textGroupTag.Text.Trim() -ne "") {
            $params.GroupTag = $textGroupTag.Text.Trim()
            $txtOutput.AppendText("Group tag: $($params.GroupTag)`r`n")
        }
        
        if ($textAssignedUser.Text.Trim() -ne "") {
            $params.AssignedUser = $textAssignedUser.Text.Trim()
            $txtOutput.AppendText("Assigned user: $($params.AssignedUser)`r`n")
        }
        
        $txtOutput.AppendText("`r`nRetrieving Windows Autopilot information...`r`n")
        $txtOutput.AppendText("=" * 60 + "`r`n")
        
        # Execute Get-WindowsAutopilotInfo
        if ($params.Count -gt 0) {
            $result = Get-WindowsAutopilotInfo @params 2>&1
        } else {
            $result = Get-WindowsAutopilotInfo 2>&1
        }
        
        # Display results
        if ($result) {
            $txtOutput.AppendText($result.ToString())
        }
        
        $txtOutput.AppendText("`r`n" + "=" * 60 + "`r`n")
        $txtOutput.AppendText("Operation completed successfully!`r`n")
        $lblStatus.Text = "Autopilot information retrieved successfully"
        $lblStatus.ForeColor = [System.Drawing.Color]::Green
        
    } catch {
        $errorMsg = $_.Exception.Message
        $txtOutput.AppendText("`r`nERROR: $errorMsg`r`n")
        $lblStatus.Text = "Error occurred while retrieving Autopilot information"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
})

$btnClear.Add_Click({
    $txtOutput.Clear()
    $lblStatus.Text = "Ready to retrieve Autopilot information"
    $lblStatus.ForeColor = [System.Drawing.Color]::Blue
})

$btnExit.Add_Click({
    $form.Close()
})

# Add all main controls to the form
$form.Controls.Add($mainPanel)
$form.Controls.Add($lblStatus)
$form.Controls.Add($txtOutput)
$form.Controls.Add($btnGetInfo)
$form.Controls.Add($btnClear)
$form.Controls.Add($btnExit)

# Force initial state setup after all controls are added
$radioUpload.Checked = $true
$textFilePath.Enabled = $false
$btnBrowse.Enabled = $false
$checkAppend.Enabled = $false
$textAssignedComputerName.Enabled = $true
$checkAssign.Enabled = $true
$checkReboot.Enabled = $true

# Initialize the group tag
Update-GroupTag

# Show the form
$form.ShowDialog()
$form.Controls.Add($btnClear)
$form.Controls.Add($btnExit)

# Force initial state setup after all controls are added
$radioUpload.Checked = $true
$textFilePath.Enabled = $false
$btnBrowse.Enabled = $false
$checkAppend.Enabled = $false
$textAssignedComputerName.Enabled = $true
$checkAssign.Enabled = $true
$checkReboot.Enabled = $true

# Initialize the group tag
Update-GroupTag

# Show the form
$form.ShowDialog()

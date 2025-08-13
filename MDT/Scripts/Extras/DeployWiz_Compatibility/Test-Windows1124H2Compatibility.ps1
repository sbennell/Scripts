#Requires -RunAsAdministrator

param (
    [switch] $AsHtml
)

$coreinfoPath = "$PSScriptRoot\CoreInfo64.exe"

if (-not (Test-Path $coreinfoPath)) {
    Write-Error "CoreInfo64 not found."
    return
}

$coreinfoOutput = & $coreinfoPath -accepteula -f

$sse42Supported = $coreinfoOutput -match "SSE4.2\s+\*"
$popcntSupported = $coreinfoOutput -match "POPCNT\s+\*"

if ($AsHtml)
{
    Write-Output ("<table style=`"border-collapse: collapse;`">")
    Write-Output ("<tr>")
    Write-Output ("<td style=`"text-align: right; padding-right: 10px;`">CPU SSE4.2 support :</td>")
    Write-Output ("<td style=`"text-align: left;`">" + $(if ($sse42Supported)  { "<span style=`"color: green;`">&#9989; Yes" } else { "<span style=`"color: red;`">&#10062; No" }) + "</span></td>")
    Write-Output ("</tr>")
    Write-Output ("<tr>")
    Write-Output ("<td style=`"text-align: right; padding-right: 10px;`">CPU POPCNT support : </td>")
    Write-Output ("<td style=`"text-align: left;`">" + $(if ($popcntSupported) { "<span style=`"color: green;`">&#9989; Yes" } else { "<span style=`"color: red;`">&#10062; No" }) + "</span></td>")
    Write-Output ("</tr>")
}
else
{
    Write-Output ("CPU SSE4.2 support  : " + $(if ($sse42Supported)  { "✅ Yes" } else { "❎ No" }))
    Write-Output ("CPU POPCNT support  : " + $(if ($popcntSupported) { "✅ Yes" } else { "❎ No" }))
}

# Get CPU Speed Information
$cpu = Get-CimInstance Win32_Processor

# Check processor speed (1GHz = 1000 MHz)
$cpuSpeedMHz = $cpu.MaxClockSpeed
$cpuSpeedOK = $cpuSpeedMHz -ge 1000

if ($AsHtml)
{
    Write-Output ("<tr>")
    Write-Output ("<td style=`"text-align: right; padding-right: 10px;`">CPU Speed &ge; 1000MHz :</td>")
    Write-Output ("<td style=`"text-align: left;`">" + $(if ($cpuSpeedOK)  { "<span style=`"color: green;`">&#9989; Yes" } else { "<span style=`"color: red;`">&#10062; No" }) + " (${cpuSpeedMHz}MHz)</span></td>")
    Write-Output ("</tr>")
}
else
{
    Write-Output ("CPU Speed ≥ 1000MHz : " + $(if ($cpuSpeedOK)  { "✅ Yes (${cpuSpeedMHz}MHz)" } else { "❎ No (${cpuSpeedMHz}MHz)" }))
}

# Check core count
$coreCount = $cpu.NumberOfCores
$coreCountOK = $coreCount -ge 2

if ($AsHtml)
{
    Write-Output ("<tr>")
    Write-Output ("<td style=`"text-align: right; padding-right: 10px;`">CPU Core Count &ge; 2 :</td>")
    Write-Output ("<td style=`"text-align: left;`">" + $(if ($coreCountOK)  { "<span style=`"color: green;`">&#9989; Yes" } else { "<span style=`"color: red;`">&#10062; No" }) + " ($coreCount cores)</span></td>")
    Write-Output ("</tr>")
}
else
{
    Write-Output ("CPU Core Count ≥ 2  : " + $(if ($coreCountOK)  { "✅ Yes ($coreCount cores)" } else { "❎ No ($coreCount cores)" }))
}

# Get System Memory
$ram = Get-CimInstance Win32_ComputerSystem

# Check RAM (convert to GB)
$totalRAMGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
$ramOK = $totalRAMGB -ge 4

if ($AsHtml)
{
    Write-Output ("<tr>")
    Write-Output ("<td style=`"text-align: right; padding-right: 10px;`">Memory (RAM) &ge; 4GB :</td>")
    Write-Output ("<td style=`"text-align: left;`">" + $(if ($ramOK)  { "<span style=`"color: green;`">&#9989; Yes" } else { "<span style=`"color: red;`">&#10062; No" }) + " (${totalRAMGB}GB)</span></td>")
    Write-Output ("</tr>")
}
else
{
    Write-Output ("Memory (RAM) ≥ 4GB  : " + $(if ($ramOK)  { "✅ Yes (${totalRAMGB}GB)" } else { "❎ No (${totalRAMGB}GB)" }))
}
   

# Get TPM information
$Tpm = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue

if ($AsHtml)
{
    Write-Output ("<tr>")
    Write-Output ("<td style=`"text-align: right; padding-right: 10px;`">TPM 2.0 support :</td>")
    Write-Output ("<td style=`"text-align: left;`">")
}

if ($Tpm -and $Tpm.IsEnabled_InitialValue) {
    # Parse all version numbers (in case of multiple)
    $versions = $Tpm.SpecVersion -split '[,\s]+' | ForEach-Object {
        try {[version]($_)} catch {} # Cast each to [version] object for comparison
    }

    # Get the highest version
    $maxVersion = $versions | Sort-Object -Descending | Select-Object -First 1

    if ($AsHtml)
    {
        if ($maxVersion -ge [version]"2.0") {
            Write-Output ("<span style=`"color: green;`">&#9989; Yes ($maxVersion)")
        }
        elseif ($maxVersion -ge [version]"1.2") {
            Write-Output ("<span style=`"color: gold;`">&#9888; Partial ($maxVersion) - e.g. Bitlocker may work with 1.2, however Intune/Autopilot will not (See: https://edust.ar/tpm)")
        }
        else {
            Write-Output "<span style=`"color: red;`">&#10062; No - TPM is too old ($maxVersion)"
        }
    }
    else
    {
        if ($maxVersion -ge [version]"2.0") {
            Write-Output ("TPM 2.0 support     : ✅ Yes ($maxVersion)")
        }
        elseif ($maxVersion -ge [version]"1.2") {
            Write-Output ("TPM 2.0 support     : ⚠ Partial ($maxVersion) - e.g. Bitlocker may work with 1.2, however Intune/Autopilot will not (See: https://edust.ar/tpm)")
        }
        else {
            Write-Output "TPM 2.0 support     : ❎ No - TPM is too old ($maxVersion)"
        }
    }
}
elseif ($AsHtml)
{
    Write-Output ("<span style=`"color: red;`">&#10062; No - TPM is not present or not enabled")
}
else
{
    Write-Output "TPM 2.0 support     : ❎ No - TPM is not present or not enabled"
}

if ($AsHtml)
{
    Write-Output ("</span></td>")
    Write-Output ("</tr>")
}

# Check Secure Boot state
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State"

if (Test-Path $regPath)
{
    $secureBoot = (Get-ItemProperty -Path $regPath -Name UEFISecureBootEnabled -ErrorAction SilentlyContinue).UEFISecureBootEnabled -eq 1
}

if ($AsHtml)
{
    Write-Output ("<tr>")
    Write-Output ("<td style=`"text-align: right; padding-right: 10px;`">Secure Boot Enabled :</td>")
    Write-Output ("<td style=`"text-align: left;`">" + $(if ($secureBoot -eq $true) { "<span style=`"color: green;`">&#9989; Yes" } else { "<span style=`"color: red;`">&#10062; No" }) + "</span></td>")
    Write-Output ("</tr>")
    Write-Output ("</table>")
}
else
{
    Write-Output ("Secure Boot Enabled : " + $(if ($secureBoot -eq $true) { "✅ Yes" } else { "❎ No" }))
}

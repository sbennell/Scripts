$PrinterPort = '\\print\Library KM BH C451i'

# Check if the printer port exists
$PortExists = Get-Printer -Name $PrinterPort -ErrorAction SilentlyContinue

# Output result and set exit code
if ($PortExists) {
    Write-Output "Printer port $PrinterPort is installed."
    Exit 0
} else {
    Write-Output "Printer port $PrinterPort is not installed."
    Exit 1
}

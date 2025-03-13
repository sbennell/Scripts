# Set Display Scaling to 125% (LogPixels 120 = 125%)
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LogPixels" -Value 120
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win8DpiScaling" -Value 1

# Optional: Restart Explorer (User will notice screen refresh)
Stop-Process -Name explorer -Force
Start-Process explorer
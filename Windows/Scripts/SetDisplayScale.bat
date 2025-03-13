@echo off
REM Set Display Scaling to 125% (LogPixels 120 = 125%)
REG ADD "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 120 /f
REG ADD "HKCU\Control Panel\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f

REM Restart Explorer to Apply Changes
taskkill /f /im explorer.exe
start explorer.exe

echo Display scaling set to 125%
pause

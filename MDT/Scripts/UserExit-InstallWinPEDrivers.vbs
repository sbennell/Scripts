Function UserExit(sType, sWhen, sDetail, bSkip)
	Dim shell, command, exitCode, scriptPath, psScript
	
	' Create a WScript Shell object
	Set shell = CreateObject("WScript.Shell")
	
	' Get the path of the current script
	scriptPath = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
	
	' Define the PowerShell script path
	psScript = scriptPath & "UserExit-InstallWinPEDrivers.ps1"
	
	' Check if PowerShell script exists
	If Not CreateObject("Scripting.FileSystemObject").FileExists(psScript) Then
	    WScript.Echo "PowerShell script not found: " & psScript
	    WScript.Quit 1 ' Exit with error code
	End If
	
	' Construct the command to execute the PowerShell script with verbose logging
	command = "powershell.exe -ExecutionPolicy Bypass -File """ & psScript & """ -Verbose"
	
	' Execute the command
	exitCode = shell.Run(command, 0, True) ' 0 means hidden, True waits for completion
	
	' Clean up
	Set shell = Nothing

	UserExit = Success
End Function

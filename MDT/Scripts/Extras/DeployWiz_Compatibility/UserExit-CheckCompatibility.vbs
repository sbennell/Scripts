Function UserExit(sType, sWhen, sDetail, bSkip) 
	UserExit = Success
End Function
Function CheckCompatibility()
    Dim objShell, intWindowPos, ObjExec, strFromProc
	Dim strScriptFile, objFSO, strFile
	
	On Error Resume Next
	 
	Set objShell = WScript.CreateObject("WScript.Shell")
	
	' Get script file path.
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	
	For Each drive in objFSO.Drives
		If drive.IsReady then
			strFile = drive.DriveLetter & ":\Deploy\Scripts\Extras\DeployWiz_Compatibility\Test-Windows1124H2Compatibility.ps1"
		
			If objFSO.FileExists(strFile) Then
				strScriptFile = strFile
				Exit For
			End If
		End if
	Next
	
	' Save the original window position. If system-positioned, this key will not exist.
    intWindowPos = objShell.RegRead("HKCU\Console\WindowPosition")
    On Error GoTo 0

    ' Set Y coordinate to be off-screen.
    objShell.RegWrite "HKCU\Console\WindowPosition", &H3000, "REG_DWORD"
	
	' Run Exec() and capture output
	strCmd = "X:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & strScriptFile & """ -AsHtml"
	oLogging.CreateEntry "UserExit: Run: " & strCmd, LogTypeInfo
	Set ObjExec = objShell.Exec(strCmd)
	oLogging.CreateEntry "UserExit: Command Complete.", LogTypeInfo
	
	strFromProc = ""
	
	Do
		strFromProc = strFromProc & ObjExec.StdOut.ReadLine()
	Loop While Not ObjExec.Stdout.atEndOfStream
	
	' Restore window position, if previously set. Otherwise, remove key...
    If Len(intWindowPos) > 0 Then
        objShell.RegWrite "HKCU\Console\WindowPosition", intWindowPos, "REG_DWORD"
    Else
        objShell.RegDelete "HKCU\Console\WindowPosition"
    End If
	
	oLogging.CreateEntry "UserExit: Command Output: " & strFromProc, LogTypeInfo
	
	' Return output
	CheckCompatibility = strFromProc
End Function
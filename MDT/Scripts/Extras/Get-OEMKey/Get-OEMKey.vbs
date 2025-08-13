Function GetOEMProduct()
    Dim objShell, objFSO, drive, intWindowPos, ObjExec
    Dim strFromProc, lastLine, strFile, strScriptFile
    
    Set objShell = WScript.CreateObject("WScript.Shell")
    Set objFSO   = CreateObject("Scripting.FileSystemObject")
    
    ' Loop through all drives to find the ProductKeyChecker.exe
    strScriptFile = ""
    For Each drive In objFSO.Drives
        If drive.IsReady Then
            strFile = drive.DriveLetter & ":\Deploy\Scripts\Extras\Get-OEMKey\ProductKeyChecker.exe"
            If objFSO.FileExists(strFile) Then
                strScriptFile = strFile
                Exit For
            End If
        End If
    Next
    
    ' If we didn't find the executable, exit early
    If strScriptFile = "" Then
        GetOEMProduct = "ERROR: ProductKeyChecker.exe not found"
        Exit Function
    End If
    
    ' Save original window position if it exists
    On Error Resume Next
    intWindowPos = objShell.RegRead("HKCU\Console\WindowPosition")
    On Error GoTo 0
    
    ' Move console window off-screen
    objShell.RegWrite "HKCU\Console\WindowPosition", &H3000, "REG_DWORD"
    
    ' Run and capture output
    Set ObjExec = objShell.Exec("""" & strScriptFile & """ /oem")
    
    lastLine = ""
    Do Until ObjExec.StdOut.AtEndOfStream
        strFromProc = Trim(ObjExec.StdOut.ReadLine())
        If Len(strFromProc) > 0 Then lastLine = strFromProc
    Loop
    
    ' Restore original window position
    On Error Resume Next
    If Len(intWindowPos) > 0 Then
        objShell.RegWrite "HKCU\Console\WindowPosition", intWindowPos, "REG_DWORD"
    Else
        objShell.RegDelete "HKCU\Console\WindowPosition"
    End If
    On Error GoTo 0
    
    ' Return last non-empty line
    GetOEMProduct = lastLine
    
    ' Cleanup
    Set ObjExec = Nothing
    Set objShell = Nothing
    Set objFSO   = Nothing
End Function

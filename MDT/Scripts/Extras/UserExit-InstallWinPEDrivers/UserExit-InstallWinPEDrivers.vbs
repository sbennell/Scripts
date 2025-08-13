Function UserExit(sType, sWhen, sDetail, bSkip)
    Dim shell, command, exitCode, objFSO, drive
    Dim strFile, strScriptFile
    Const Success = 0

    ' Create required objects
    Set shell = CreateObject("WScript.Shell")
    Set objFSO = CreateObject("Scripting.FileSystemObject")

    ' Loop through all drives to find the PowerShell script
    For Each drive In objFSO.Drives
        If drive.IsReady Then
            strFile = drive.DriveLetter & ":\Deploy\Scripts\Extras\UserExit-InstallWinPEDrivers\UserExit-InstallWinPEDrivers.ps1"
            If objFSO.FileExists(strFile) Then
                strScriptFile = strFile
                Exit For
            End If
        End If
    Next

    ' Handle case where script was not found
    If strScriptFile = "" Then
        WScript.Quit 1
    End If

    ' Build PowerShell command
    command = "powershell.exe -ExecutionPolicy Bypass -File """ & strScriptFile & """ -Verbose"

    ' Run PowerShell script
    exitCode = shell.Run(command, 0, True)

    ' Clean up
    Set shell = Nothing
    Set objFSO = Nothing

    UserExit = Success
End Function

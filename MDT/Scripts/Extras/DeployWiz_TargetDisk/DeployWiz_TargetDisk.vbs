' // ***************************************************************************
' // File:      DeployWiz_TargetDisk.vbs
' //
' // Version:   6.3.8456.1000
' //
' // Purpose:   Script methods used for the Target Disk UI
' //
' // ***************************************************************************

'This function is used to populate the select box
Function Disk_Initialization
    Dim oOption2
    strComputer       = "."
    Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    Set colDisks      = objWMIService.ExecQuery ("SELECT * FROM Win32_DiskDrive")

    For Each objDisks in colDisks
        Set oOption2   = document.createElement("OPTION")
		
		If (objDisks.MediaType = "Fixed hard disk media" OR objDisks.MediaType = "Fixed hard disk") Then
			oOption2.Text  = GetDiskTitle(objDisks.Index)
			oOption2.Value = objDisks.Index
			TargetDisk.Add(oOption2)
			
			If (objDisks.Index = 0) Then
				TargetDisk.Options(TargetDisk.Options.Length - 1).Selected = True
			End If
		End If
    Next

	SetTargetDisk()
End Function

'This function is used to convert bytes into useful readable size
Function ConvertSize(byteSize)
    Dim Size
    Size = byteSize

    Do While InStr(Size,",") 'Remove commas from size
        CommaLocate = InStr(Size,",")
        Size        = Mid(Size,1,CommaLocate - 1) & _
        Mid(Size,CommaLocate + 1,Len(Size) - CommaLocate)
    Loop

    Suffix = " Bytes"
    If Size >= 1024 Then suffix = " KB"
    If Size >= 1048576 Then suffix = " MB"
    If Size >= 1073741824 Then suffix = " GB"
    If Size >= 1099511627776 Then suffix = " TB"

    Select Case Suffix
        Case " KB" Size = Round(Size / 1024, 1)
        Case " MB" Size = Round(Size / 1048576, 1)
        Case " GB" Size = Round(Size / 1073741824, 1)
        Case " TB" Size = Round(Size / 1099511627776, 1)
    End Select

    ConvertSize = Size & Suffix
End Function

'this function is used to show disk info about a selected disk
Function ShowDiskInfo

    strSelectedIndex = ""
    ' Check all the Options of the ListBox

    For i = 0 To (TargetDisk.Options.Length - 1)
        ' Check if the Current Option is Selected

        If (TargetDisk.Options(i).Selected) Then
            ' Collect only the Selected Values
            strSelectedIndex = strSelectedIndex & TargetDisk.Options(i).Value & vbCrLf
        End If

    Next

    strComputer = "."
    Dim sMsg
    Dim sDiskSize
    Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    Set colDiskInfo   = objWMIService.ExecQuery ("SELECT * FROM Win32_DiskDrive WHERE Index=" & strSelectedIndex)

    For Each objDiskInfo in colDiskInfo
        sDiskSize = ConvertSize(objDiskInfo.Size)
        sMsg      = "Disk Index: " & strSelectedIndex & vbCrLf & "Disk Size: " & sDiskSize & vbCrLf & "Disk Model: " & objDiskInfo.Model & vbCrLf & "Disk Serial Number: " & objDiskInfo.SerialNumber
        MsgBox(sMsg)
    Next

End Function

'this function is used to show disk info about a selected disk
Function GetDiskTitle(strSelectedIndex)

    strComputer = "."
    Dim sMsg
    Dim sDiskSize
    Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    Set colDiskInfo   = objWMIService.ExecQuery ("SELECT * FROM Win32_DiskDrive WHERE Index=" & strSelectedIndex)

    For Each objDiskInfo in colDiskInfo
        sDiskSize    = ConvertSize(objDiskInfo.Size)
        GetDiskTitle = "[" & strSelectedIndex & "]  " & objDiskInfo.Model & " (" & sDiskSize & ")" & " (Serial: " & objDiskInfo.SerialNumber & ")"
    Next

End Function

'this function sets the variable in MDT for the deployment
Function SetTargetDisk

    strTargetDiskIndex = ""
    ' Check all the Options of the ListBox

    For i = 0 To (TargetDisk.Options.Length - 1)
        ' Check if the Current Option is Selected

        If (TargetDisk.Options(i).Selected) Then
            ' Collect only the Selected Values
            strTargetDiskIndex = strTargetDiskIndex & TargetDisk.Options(i).Value & vbCrLf
        End If

    Next

    oEnvironment.Item("OSDDiskIndex") = strTargetDiskIndex

End Function

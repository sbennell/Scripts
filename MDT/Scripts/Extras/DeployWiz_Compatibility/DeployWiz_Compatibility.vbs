' // ***************************************************************************
' // File:      DeployWiz_Compatibility.vbs
' //
' // Version:   6.3.8456.1000
' //
' // Purpose:   Script methods used for the Compatibility Check UI
' //
' // ***************************************************************************

Function InitializeCompatibilityInfo
	Dim oItem, sXPathOld
	
	If oEnvironment.Item("CompatibilityInfo24H2") <> "" Then
		CompatibilityInfo24H2.InnerHTML = oEnvironment.Item("CompatibilityInfo24H2")
	End If
	
	PopulateElements

End function

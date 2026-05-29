' Lance l'API Manager sans fenetre console (demarrage automatique Windows)
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
batPath = fso.BuildPath(scriptDir, "start_manager_api.bat")

If Not fso.FileExists(batPath) Then
  WScript.Quit 1
End If

' 0 = fenetre masquee
shell.Run """" & batPath & """", 0, False

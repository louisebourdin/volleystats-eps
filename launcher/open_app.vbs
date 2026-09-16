' Lance VolleyStats EPS comme une application : démarre le petit serveur local
' (silencieux, sans fenêtre) puis ouvre Chrome en mode application (sans barre
' d'adresse ni onglets), pour une vraie expérience "app" au double-clic.

Dim shell, fso, scriptDir, chromePath, url

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
url = "http://localhost:8765/"

' Démarre le serveur local (ne fait rien s'il tourne déjà - voir serve.ps1)
shell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptDir & "\serve.ps1""", 0, False

' Laisse le temps au serveur de démarrer au tout premier lancement
WScript.Sleep 900

chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
If fso.FileExists(chromePath) Then
    shell.Run """" & chromePath & """ --app=" & url & " --window-size=1320,880", 1, False
Else
    shell.Run url, 1, False
End If

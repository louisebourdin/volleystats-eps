' Lance VolleyStats EPS comme une application : ouvre Chrome en mode
' application (sans barre d'adresse ni onglets) pointé sur la version en
' ligne, pour une vraie experience "app" au double-clic.
'
' Depuis la mise en place de la mise a jour automatique (GitHub + Netlify),
' ce raccourci utilise directement le lien en ligne : il est donc toujours
' a jour, meme apres une modification faite depuis un autre appareil (iPad,
' etc.), sans avoir besoin de reconstruire quoi que ce soit sur ce PC.

Dim shell, fso, chromePath, url

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
url = "https://moonlit-youtiao-44fcd5.netlify.app/"

chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
If fso.FileExists(chromePath) Then
    shell.Run """" & chromePath & """ --app=" & url & " --window-size=1320,880", 1, False
Else
    shell.Run url, 1, False
End If

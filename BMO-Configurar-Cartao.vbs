' Launcher invisivel para o Assistente BMO no Windows
' Oculta a janela de terminal do PowerShell e abre direto a interface minimalista
Set WshShell = CreateObject("WScript.Shell")
strCurDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
strCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strCurDir & "\scripts\windows\BMO-Preparar-Cartao.ps1"""
WshShell.Run strCommand, 0, False

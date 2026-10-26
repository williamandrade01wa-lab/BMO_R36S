@echo off
setlocal
title BMO - Iniciar Codex
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\INICIAR-CODEX.ps1" %*
set "BMO_RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %BMO_RESULT%

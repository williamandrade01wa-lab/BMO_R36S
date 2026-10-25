@echo off
setlocal
set "BMO_LOG_DIR=%LOCALAPPDATA%\BMO\Logs"
if not exist "%BMO_LOG_DIR%" mkdir "%BMO_LOG_DIR%" 2>nul
if not exist "%BMO_LOG_DIR%" set "BMO_LOG_DIR=%TEMP%"
set "BMO_START_LOG=%BMO_LOG_DIR%\BMO-Inicializacao-%RANDOM%-%RANDOM%.log"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0BMO-Preparar-Cartao.ps1" >"%BMO_START_LOG%" 2>&1
set "BMO_EXIT=%ERRORLEVEL%"
if not "%BMO_EXIT%"=="0" (
  echo Nao foi possivel concluir o Assistente BMO.
  echo Diagnostico de inicializacao: "%BMO_START_LOG%"
  echo Extraia todos os arquivos para uma pasta no PC antes de abrir.
  pause
) else (
  for %%F in ("%BMO_START_LOG%") do if %%~zF==0 del "%BMO_START_LOG%" 2>nul
)
endlocal & exit /b %BMO_EXIT%

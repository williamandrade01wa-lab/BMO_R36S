@echo off
setlocal
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0BMO-Preparar-Cartao.ps1"
if errorlevel 1 (
  echo Nao foi possivel abrir o assistente. Mantenha todos os arquivos extraidos na mesma pasta.
  pause
)
endlocal

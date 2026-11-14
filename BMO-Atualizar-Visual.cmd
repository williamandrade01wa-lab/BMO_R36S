@echo off
where py >nul 2>nul
if errorlevel 1 goto python
py -3 "%~dp0scripts\update-visual.py" %*
exit /b %errorlevel%
:python
python "%~dp0scripts\update-visual.py" %*
exit /b %errorlevel%

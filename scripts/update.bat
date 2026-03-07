@echo off
REM scripts/update.bat - Entry point for Windows
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1" %*
exit /b %ERRORLEVEL%

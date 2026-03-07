@echo off
REM scripts/audit.bat - Entry point for Windows
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0audit.ps1" %*
exit /b %ERRORLEVEL%

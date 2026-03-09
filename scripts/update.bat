@echo off
REM scripts/update.bat - Entry point for Windows
REM Delegates to update.ps1 to maintain Single Source of Truth.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1" %*
exit /b %ERRORLEVEL%

@echo off
REM scripts/audit.bat - Entry point for Windows
REM Delegates to audit.ps1 to maintain Single Source of Truth.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0audit.ps1" %*
exit /b %ERRORLEVEL%

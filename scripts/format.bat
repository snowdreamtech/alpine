@echo off
REM scripts/format.bat - Entry point for Windows
REM Delegates to format.ps1 to maintain Single Source of Truth.REM Delegates to format.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0format.ps1" %*
exit /b %ERRORLEVEL%

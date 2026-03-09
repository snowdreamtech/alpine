@echo off
REM scripts/docs.bat - Entry point for Windows
REM Delegates to docs.ps1 to maintain Single Source of Truth.REM Delegates to docs.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0docs.ps1" %*
exit /b %ERRORLEVEL%

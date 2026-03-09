@echo off
REM scripts/env.bat - Entry point for Windows
REM Delegates to env.ps1 to maintain Single Source of Truth.REM Delegates to env.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0env.ps1" %*
exit /b %ERRORLEVEL%

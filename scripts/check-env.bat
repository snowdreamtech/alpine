@echo off
REM scripts/check-env.bat - Entry point for Windows
REM Delegates to check-env.ps1 to maintain Single Source of Truth.REM Delegates to check-env.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-env.ps1" %*
exit /b %ERRORLEVEL%

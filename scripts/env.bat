@echo off
REM scripts/env.bat - Windows wrapper for scripts/env.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0env.ps1" %*
exit /b %ERRORLEVEL%

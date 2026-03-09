@echo off
REM scripts/audit.bat - Windows wrapper for scripts/audit.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0audit.ps1" %*
exit /b %ERRORLEVEL%

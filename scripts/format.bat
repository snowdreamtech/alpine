@echo off
REM scripts/format.bat - Windows wrapper for scripts/format.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0format.ps1" %*
exit /b %ERRORLEVEL%

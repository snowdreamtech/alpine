@echo off
REM scripts/cleanup.bat - Windows wrapper for scripts/cleanup.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cleanup.ps1" %*
exit /b %ERRORLEVEL%

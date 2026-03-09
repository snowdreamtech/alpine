@echo off
REM scripts/check-env.bat - Windows wrapper for scripts/check-env.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-env.ps1" %*
exit /b %ERRORLEVEL%

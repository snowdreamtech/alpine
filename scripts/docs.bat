@echo off
REM scripts/docs.bat - Windows wrapper for scripts/docs.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0docs.ps1" %*
exit /b %ERRORLEVEL%

@echo off
REM scripts/install.bat - Windows wrapper for scripts/install.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
exit /b %ERRORLEVEL%

@echo off
REM scripts/test.bat - Windows wrapper for scripts/test.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1" %*
exit /b %ERRORLEVEL%

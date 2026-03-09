@echo off
REM scripts/lint.bat - Windows wrapper for scripts/lint.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lint.ps1" %*
exit /b %ERRORLEVEL%

@echo off
REM scripts/archive-changelog.bat - Windows wrapper for scripts/archive-changelog.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0archive-changelog.ps1" %*
exit /b %ERRORLEVEL%

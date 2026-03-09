@echo off
REM scripts/init-project.bat - Windows wrapper for scripts/init-project.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init-project.ps1" %*
exit /b %ERRORLEVEL%

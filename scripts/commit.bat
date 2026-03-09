@echo off
REM scripts/commit.bat - Windows wrapper for scripts/commit.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0commit.ps1" %*
exit /b %ERRORLEVEL%

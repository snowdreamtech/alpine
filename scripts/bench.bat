@echo off
REM scripts/bench.bat - Windows wrapper for scripts/bench.sh
REM
REM Professional delegation to PowerShell to maintain Single Source of Truth (SSoT).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bench.ps1" %*
exit /b %ERRORLEVEL%

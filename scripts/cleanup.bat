@echo off
REM scripts/cleanup.bat - Entry point for Windows
REM Delegates to cleanup.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cleanup.ps1" %*
exit /b %ERRORLEVEL%

@echo off
REM scripts/setup.bat - Entry point for Windows
REM Delegates to setup.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
exit /b %ERRORLEVEL%

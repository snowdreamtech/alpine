@echo off
REM scripts/install.bat - Entry point for Windows
REM Delegates to install.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
exit /b %ERRORLEVEL%

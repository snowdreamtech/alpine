@echo off
REM scripts\setup.cmd - Project Setup Script for Windows (CMD Wrapper)
REM This script delegates to setup.ps1, which in turn delegates to setup.sh.

echo [CMD] Delegating setup to PowerShell...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0setup.ps1" %*
exit /b %ERRORLEVEL%

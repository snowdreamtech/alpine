@echo off
REM scripts/verify.bat - Entry point for Windows
REM Delegates to verify.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify.ps1" %*
exit /b %ERRORLEVEL%

@echo off
REM scripts/test.bat - Entry point for Windows
REM Delegates to test.ps1 to maintain Single Source of Truth.REM Delegates to test.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1" %*
exit /b %ERRORLEVEL%

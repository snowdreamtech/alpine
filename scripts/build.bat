@echo off
REM scripts/build.bat - Entry point for Windows
REM Delegates to build.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
exit /b %ERRORLEVEL%

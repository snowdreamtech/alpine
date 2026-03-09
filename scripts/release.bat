@echo off
REM scripts/release.bat - Entry point for Windows
REM Delegates to release.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0release.ps1" %*
exit /b %ERRORLEVEL%

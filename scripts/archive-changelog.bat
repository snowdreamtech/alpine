@echo off
REM scripts/archive-changelog.bat - Entry point for Windows
REM Delegates to archive-changelog.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0archive-changelog.ps1" %*
exit /b %ERRORLEVEL%

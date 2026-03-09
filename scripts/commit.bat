@echo off
REM scripts/commit.bat - Entry point for Windows
REM Delegates to commit.ps1 to maintain Single Source of Truth.REM Delegates to commit.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0commit.ps1" %*
exit /b %ERRORLEVEL%

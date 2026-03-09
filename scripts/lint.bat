@echo off
REM scripts/lint.bat - Entry point for Windows
REM Delegates to lint.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lint.ps1" %*
exit /b %ERRORLEVEL%

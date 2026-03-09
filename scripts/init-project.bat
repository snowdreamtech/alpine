@echo off
REM scripts/init-project.bat - Entry point for Windows
REM Delegates to init-project.ps1 to maintain Single Source of Truth.REM Delegates to init-project.ps1 to maintain Single Source of Truth.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init-project.ps1" %*
exit /b %ERRORLEVEL%

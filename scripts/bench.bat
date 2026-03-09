@echo off
REM scripts/bench.bat - Entry point for Windows
REM Delegates to bench.ps1 to maintain Single Source of Truth.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bench.ps1" %*
exit /b %ERRORLEVEL%

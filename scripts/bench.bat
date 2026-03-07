@echo off
REM scripts/bench.bat - Entry point for Windows
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bench.ps1" %*
exit /b %ERRORLEVEL%

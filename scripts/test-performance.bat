@echo off
REM CMD wrapper — delegates to test-performance.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test-performance.ps1" %*

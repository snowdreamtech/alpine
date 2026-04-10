@echo off
REM CMD wrapper — delegates to compare-performance.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0compare-performance.ps1" %*

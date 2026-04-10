@echo off
REM CMD wrapper — delegates to collect-baseline.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0collect-baseline.ps1" %*

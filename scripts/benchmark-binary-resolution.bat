@echo off
REM CMD wrapper — delegates to benchmark-binary-resolution.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0benchmark-binary-resolution.ps1" %*

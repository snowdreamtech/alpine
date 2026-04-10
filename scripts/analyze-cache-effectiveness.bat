@echo off
REM CMD wrapper — delegates to analyze-cache-effectiveness.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0analyze-cache-effectiveness.ps1" %*

@echo off
REM CMD wrapper — delegates to analyze-performance-trends.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0analyze-performance-trends.ps1" %*

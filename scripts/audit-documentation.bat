@echo off
REM CMD wrapper — delegates to audit-documentation.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0audit-documentation.ps1" %*

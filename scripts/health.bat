@echo off
:: scripts/health.bat - Windows Delegation Wrapper
:: CMD wrapper that delegates to PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0health.ps1" %*

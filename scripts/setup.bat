@echo off
:: scripts/setup.bat - CMD wrapper for setup.ps1
:: This provides a familiar entry point for Windows developers.

echo 🚀 Launching PowerShell setup script...
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

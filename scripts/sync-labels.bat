@echo off
:: sync-labels.bat
:: Purpose: Windows entry point for label synchronization.
:: Design: Delegates to PowerShell for robust GitHub CLI interaction.

set SCRIPT_DIR=%~dp0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%sync-labels.ps1" %*

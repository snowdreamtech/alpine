@echo off
rem scripts/sync-docs.bat - Documentation Sync Wrapper (Batch)
rem Purpose: CMD-compatible entry point that delegates to PowerShell.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-docs.ps1" %*

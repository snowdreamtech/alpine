@echo off
REM scripts/gen-full-manifest.bat - Windows wrapper for scripts/gen-full-manifest.sh
REM
REM Purpose:
REM   Programmatically generates a comprehensive mise.toml containing all
REM   Tier 1 (Core) and Tier 2 (On-demand) tools.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
#   - "World Class" AI Documentation (English-only).
#   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gen-full-manifest.ps1" %*
exit /b %ERRORLEVEL%

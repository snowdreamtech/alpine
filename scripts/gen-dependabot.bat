@echo off
REM scripts/gen-dependabot.bat - Windows wrapper for scripts/gen-dependabot.sh
REM
REM Purpose:
REM   Scans the repository for manifest files and generates a minimal dependabot.yml.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (General), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gen-dependabot.ps1" %*
exit /b %ERRORLEVEL%

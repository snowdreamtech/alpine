@echo off
REM scripts/bench.bat - Windows wrapper for scripts/bench.sh
REM
REM Purpose:
REM   Orchestrates performance benchmarking across the project.
REM   Delegates to PowerShell to maintain Single Source of Truth (SSoT).
REM
REM Standards:
REM   - CMD delegation to PowerShell.
REM   - "World Class" AI Documentation (English-only).
REM   - Rule 01 (Idempotency), Rule 03 (Architecture).

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bench.ps1" %*
exit /b %ERRORLEVEL%

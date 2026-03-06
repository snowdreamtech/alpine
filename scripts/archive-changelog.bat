@echo off
REM scripts/archive-changelog.bat - Entry point for Windows
REM Follows the cmd -> powershell -> shell pattern.

setlocal
set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%archive-changelog.ps1

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

if %ERRORLEVEL% neq 0 (
    exit /b %ERRORLEVEL%
)

endlocal

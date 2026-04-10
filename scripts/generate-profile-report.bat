@echo off
REM scripts/generate-profile-report.bat - CMD wrapper for generate-profile-report.sh

setlocal

set "SCRIPT_DIR=%~dp0"
set "SH_SCRIPT=%SCRIPT_DIR%generate-profile-report.sh"

if not exist "%SH_SCRIPT%" (
    echo Error: Shell script not found: %SH_SCRIPT%
    exit /b 1
)

bash "%SH_SCRIPT%" %*
exit /b %ERRORLEVEL%

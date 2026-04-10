@echo off
REM scripts/validate-doc-examples.bat - CMD wrapper for validate-doc-examples.sh

setlocal

set "SCRIPT_DIR=%~dp0"
set "SH_SCRIPT=%SCRIPT_DIR%validate-doc-examples.sh"

if not exist "%SH_SCRIPT%" (
    echo Error: Shell script not found: %SH_SCRIPT%
    exit /b 1
)

bash "%SH_SCRIPT%" %*
exit /b %ERRORLEVEL%

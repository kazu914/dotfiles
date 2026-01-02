@echo off
REM VSCode settings setup wrapper for Windows
REM This batch file runs the PowerShell script with appropriate permissions

setlocal

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%setup.ps1

echo === VSCode Settings Setup ===
echo.

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo Error: PowerShell script not found: %PS_SCRIPT%
    pause
    exit /b 1
)

REM Check for clean flag
if "%1"=="clean" (
    echo Running cleanup...
    powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Clean
    goto :end
)

if "%1"=="-clean" (
    echo Running cleanup...
    powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Clean
    goto :end
)

REM Check for force flag
if "%1"=="force" (
    echo Running setup with force option...
    powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Force
    goto :end
)

if "%1"=="-force" (
    echo Running setup with force option...
    powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Force
    goto :end
)

REM Default: run setup
echo Running setup...
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

:end
echo.
pause

@echo off
:: ============================================================
:: AdaSpace3D - One-Click Build & Flash Launcher
:: ============================================================
:: This script launches the PowerShell builder with proper
:: execution policy bypass and passes the current directory.
:: ============================================================

title AdaSpace3D Firmware Builder

:: Change to the directory where this batch file is located
cd /d "%~dp0"

:: Launch PowerShell with execution policy bypass
:: Using -Command and $PWD to get clean path without quote issues
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\builder.ps1"

:: Pause so the user can see success/error messages
echo.
echo ============================================================
echo Press any key to close this window...
pause >nul

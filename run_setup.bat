@echo off
REM Self-elevate if this wasn't already launched as Administrator. Double-
REM clicking a desktop shortcut never starts elevated on its own, and
REM setup.ps1 -> install_powertoys.ps1 needs admin rights to actually write
REM into C:\Program Files\PowerToys - without this, the PowerToys installer
REM can silently fail to place files there while still looking like it
REM succeeded (no visible error, clean exit code, just no PowerToys.exe).
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run
) else (
    echo Requesting administrator privileges - click Yes on the prompt...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:run
powershell -NoProfile -ExecutionPolicy Bypass -sta -File "%~dp0setup.ps1"

@echo off
call "%~dp0config.bat"
if "%BROKER_HOST%"=="" (
    echo ERROR: BROKER_HOST is not set. Run the setup icon first.
    pause
    exit /b 1
)
echo Refresh listener active on %BROKER_HOST%:%BROKER_PORT%, topic "%TOPIC%" ...
:loop
"C:\Program Files\mosquitto\mosquitto_sub.exe" -h %BROKER_HOST% -p %BROKER_PORT% -i %TOPIC%_refresh -t "%TOPIC%" -C 1 > "%temp%\mqtt_refresh_msg.txt"
set /p MSG=<"%temp%\mqtt_refresh_msg.txt"
if "%MSG%"=="%REFRESH_SECRET%" (
    powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0send_key.ps1" -ProcessName "%BROWSER_PROCESS%" -Key "F5"
) else if "%MSG%"=="%CLEARCACHE_SECRET%" (
    powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0send_key.ps1" -ProcessName "%BROWSER_PROCESS%" -Key "F9"
)
goto loop

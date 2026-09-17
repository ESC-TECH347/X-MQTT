@echo off
call "%~dp0config.bat"
if "%BROKER_HOST%"=="" (
    echo ERROR: BROKER_HOST is not set. Run the setup icon first.
    pause
    exit /b 1
)
echo Listening on %BROKER_HOST%:%BROKER_PORT%, topic "%TOPIC%" ...
:loop
"C:\Program Files\mosquitto\mosquitto_sub.exe" -h %BROKER_HOST% -p %BROKER_PORT% -i %TOPIC%_listener -t "%TOPIC%" -C 1 > "%temp%\mqtt_msg.txt"
set /p MSG=<"%temp%\mqtt_msg.txt"
if "%MSG%"=="%SECRET%" (
    shutdown /s /t 30 /c "Remote shutdown via MQTT"
) else if "%MSG%"=="%RESTART_SECRET%" (
    shutdown /r /t 30 /c "Remote restart via MQTT"
)
goto loop

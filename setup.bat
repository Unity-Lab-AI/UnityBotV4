@echo off
setlocal enabledelayedexpansion

echo Use .env file for configuration? (Y/N):
set /p use_env=
if /I "%use_env%"=="Y" (
    set TARGET=env
) else (
    set TARGET=system
)

call :prompt_var DISCORD_TOKEN
call :prompt_var POLLINATIONS_TOKEN

pip install -r requirements.txt

echo Setup complete.
pause
goto :eof

:prompt_var
set var=%1
if "%TARGET%"=="system" (
    for /f "tokens=2 delims==" %%A in ('set %var% 2^>nul') do set current=%%A
    if defined current (
        echo %var% already set. Skipping prompt.
    ) else (
        set /p value=Enter value for %var%:
        setx %var% "%value%" >nul
        set %var%=%value%
    )
) else (
    if exist .env (
        findstr /v /b "%var%=" .env > .env.tmp
        move /y .env.tmp .env >nul
    )
    set /p value=Enter value for %var%:
    echo %var%=%value%>>.env
)
goto :eof


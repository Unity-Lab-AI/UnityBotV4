@echo off
setlocal enabledelayedexpansion

REM Ensure pyenv and Python are available
set "PYENV=%USERPROFILE%\.pyenv"
set "PATH=%PYENV%\pyenv-win\bin;%PYENV%\pyenv-win\shims;%PATH%"

where pyenv >nul 2>&1
if errorlevel 1 (
    echo pyenv not found. Installing...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing https://pyenv.win/install.ps1 ^| Invoke-Expression"
    set "PATH=%PYENV%\pyenv-win\bin;%PYENV%\pyenv-win\shims;%PATH%"
)

set "PY_VERSION=3.11.6"
pyenv install -s %PY_VERSION% || exit /b 1
pyenv virtualenv -f %PY_VERSION% unitybot-env >nul 2>&1 || exit /b 1
pyenv local unitybot-env || exit /b 1

echo Use .env file for configuration? (Y/N):
set /p use_env=
if /I "%use_env%"=="Y" (
    set TARGET=env
) else (
    set TARGET=system
)

call :prompt_var DISCORD_TOKEN
call :prompt_var POLLINATIONS_TOKEN

pip install -r requirements.txt || exit /b 1

echo Setup complete.
pause
goto :eof

:prompt_var
set "var=%~1"
set "env_value="
for /f "tokens=2 delims==" %%A in ('set %var% 2^>nul') do set "env_value=%%A"

if "%TARGET%"=="env" (
    set "file_value="
    if exist .env (
        for /f "tokens=2 delims==" %%A in ('findstr /b "%var%=" .env') do set "file_value=%%A"
    )
    if defined file_value (
        echo %var% already set in .env. Skipping prompt.
    ) else (
        set /p value=Enter value for %var%:
        if "!value!"=="" if defined env_value set "value=!env_value!"
        if exist .env (
            findstr /v /b "%var%=" .env > .env.tmp
            move /y .env.tmp .env >nul
        )
        echo %var%=%value%>>.env
    )
) else (
    if defined env_value (
        echo %var% already set. Skipping prompt.
    ) else (
        set /p value=Enter value for %var%:
        setx %var% "%value%" >nul
        set "%var%=%value%"
    )
)
goto :eof


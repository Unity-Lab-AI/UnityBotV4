@echo off
setlocal enabledelayedexpansion

REM Ensure Python is available without compiling
where python >nul 2>&1
if errorlevel 1 (
    echo Python not found. Downloading installer...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe -OutFile python-installer.exe" || exit /b 1
    echo Installing Python...
    start /wait python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 SimpleInstall=1 || exit /b 1
    del python-installer.exe
)

for /f "tokens=2 delims= " %%I in ('python -V 2^>^&1') do set PY_VER=%%I
for /f "tokens=1,2 delims=." %%a in ("%PY_VER%") do (
    set MAJOR=%%a
    set MINOR=%%b
)
if %MAJOR% LSS 3 (
    echo Python 3.8+ is required.
    exit /b 1
)
if %MAJOR%==3 if %MINOR% LSS 8 (
    echo Python 3.8+ is required.
    exit /b 1
)

if not exist .venv (
    python -m venv .venv || exit /b 1
)
call .venv\Scripts\activate.bat

echo Use .env file for configuration? (Y/N):
set /p use_env=
if /I "%use_env%"=="Y" (
    set TARGET=env
) else (
    set TARGET=system
)

call :prompt_var DISCORD_TOKEN
call :prompt_var POLLINATIONS_TOKEN

python -m pip install -U pip || exit /b 1
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


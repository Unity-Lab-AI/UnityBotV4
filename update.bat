@echo off
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
cd /d %SCRIPT_DIR%

for /f "tokens=1,2,*" %%a in ('tasklist /fi "imagename eq python.exe" /v ^| findstr /i "bot.py"') do (
    taskkill /PID %%b /F >nul 2>&1
)

if exist .env (
    move /Y .env "%USERPROFILE%\Desktop\unitybot.env" >nul
)

git fetch
git pull

pip install -r requirements.txt

if exist "%USERPROFILE%\Desktop\unitybot.env" (
    move /Y "%USERPROFILE%\Desktop\unitybot.env" .env >nul
)

echo Update complete. Restarting bot...
python bot.py


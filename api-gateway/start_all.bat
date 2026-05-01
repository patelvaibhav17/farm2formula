@echo off
setlocal enabledelayedexpansion

echo ======================================================
echo 🚀 Farm2Formula: Starting Full Backend (Plan V2)
echo ======================================================

echo.
echo [1/4] ⛓️  Check Docker status...
docker info >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ ERROR: Docker is not responding! 
    echo Please make sure Docker Desktop is running and wait 30 seconds.
    pause
    exit /b
)

echo.
echo [2/4] 🏰 Starting Hyperledger Fabric Network (WSL)...
echo This takes about 2-3 minutes. Clearing old state first...
wsl bash /mnt/d/Vaibhav/up.sh

echo.
echo [3/4] ⏳ Waiting for Windows-WSL Sync (10 seconds)...
echo Almost there! Giving the file system a moment to catch up...
timeout /t 10 /nobreak >nul

echo.
echo [4/4] 🌉 Starting API Gateway...
call npm start

pause

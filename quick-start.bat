@echo off
REM OpenClaw Hardened Edition - Quick Start Script for Windows
REM This script helps you set up OpenClaw quickly

echo ================================================
echo OpenClaw Hardened Edition - Quick Start
echo ================================================
echo.

REM Check if Docker is running
echo [1/5] Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed or not running
    echo Please install Docker Desktop from:
    echo https://www.docker.com/products/docker-desktop/
    echo.
    pause
    exit /b 1
)
echo [OK] Docker is running
echo.

REM Check if Node.js is installed
echo [2/5] Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed
    echo Please install Node.js LTS from:
    echo https://nodejs.org
    echo.
    pause
    exit /b 1
)
echo [OK] Node.js is installed
echo.

REM Check if .env file exists
echo [3/5] Checking configuration...
if not exist .env (
    echo [WARNING] .env file not found
    echo Creating .env from template...
    copy .env.example .env
    echo.
    echo IMPORTANT: Edit .env file and add your credentials:
    echo  - GMAIL_APP_PASSWORD
    echo  - TELEGRAM_BOT_TOKEN
    echo  - TELEGRAM_OWNER_CHAT_ID
    echo  - ANTHROPIC_API_KEY
    echo.
    echo Press any key to open .env in Notepad...
    pause >nul
    notepad .env
)
echo [OK] Configuration file exists
echo.

REM Install dependencies
echo [4/5] Installing dependencies...
echo This may take 5-10 minutes...
call npm install
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed
echo.

REM Build application
echo [5/5] Building application...
call npm run build
if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo [OK] Build complete
echo.

echo ================================================
echo Setup Complete!
echo ================================================
echo.
echo Next steps:
echo.
echo 1. Make sure your .env file has all credentials filled in
echo 2. Run: docker-compose -f docker\docker-compose.yml up -d
echo 3. Access at: http://localhost:3000
echo.
echo For detailed instructions, see: WINDOWS_SETUP.md
echo.
pause

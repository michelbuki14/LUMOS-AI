@echo off
REM LUMOS AI - Local Startup Script
REM Starts all services for local development

echo ========================================
echo   LUMOS AI - Starting Local Services
echo ========================================

REM Create storage directories
if not exist "storage" mkdir storage
if not exist "exports" mkdir exports
if not exist "models" mkdir models

REM Set environment variables
set DATABASE_URL=sqlite+aiosqlite:///C:/Users/miche/Documents/GitHub/lumos-ai/lumos_local.db
set PYTHONPATH=C:\Users\miche\Documents\GitHub\lumos-ai\services\api
set JWT_SECRET=local_dev_secret
set APP_ENV=local
set STORAGE_DIR=C:\Users\miche\Documents\GitHub\lumos-ai\storage
set MODEL_DIR=C:\Users\miche\Documents\GitHub\lumos-ai\models

REM Start API Server
echo.
echo [1/3] Starting API Server on port 8000...
start "LUMOS API" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\services\api && python -m uvicorn lumos.app:app --reload --host 0.0.0.0 --port 8000"

REM Wait for API to start
timeout /t 5 /nobreak >nul

REM Start AI Service
echo [2/3] Starting AI Service on port 8001...
start "LUMOS AI Service" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\services\ai && python -m uvicorn lumos.ai.app:app --reload --host 0.0.0.0 --port 8001"

REM Wait for AI service to start
timeout /t 3 /nobreak >nul

REM Start Flutter Desktop App
echo [3/3] Starting Flutter Desktop App...
start "LUMOS Desktop" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop && flutter run -d windows"

echo.
echo ========================================
echo   LUMOS AI is starting!
echo   API:    http://localhost:8000/docs
echo   AI:     http://localhost:8001
echo   Desktop: Flutter window should appear
echo ========================================
echo.
echo Press any key to exit this window...
pause >nul

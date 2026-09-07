@echo off
echo ========================================
echo   LUMOS AI - Starting All Services
echo ========================================

REM Create storage directories
if not exist "C:\Users\miche\Documents\GitHub\lumos-ai\storage" mkdir "C:\Users\miche\Documents\GitHub\lumos-ai\storage"
if not exist "C:\Users\miche\Documents\GitHub\lumos-ai\exports" mkdir "C:\Users\miche\Documents\GitHub\lumos-ai\exports"

REM Set environment variables
set DATABASE_URL=sqlite+aiosqlite:///C:/Users/miche/Documents/GitHub/lumos-ai/lumos_local.db
set PYTHONPATH=C:\Users\miche\Documents\GitHub\lumos-ai\services\api
set JWT_SECRET=local_dev_secret
set APP_ENV=local

echo.
echo [1/3] Starting API Server on port 8000...
start "LUMOS API" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\services\api && python -m uvicorn lumos.app:app --reload --host 0.0.0.0 --port 8000"

timeout /t 3 /nobreak >nul

echo [2/3] Starting AI Service on port 8001...
start "LUMOS AI Service" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\services\ai && python -m uvicorn lumos.ai.app:app --reload --host 0.0.0.0 --port 8001"

timeout /t 2 /nobreak >nul

echo [3/3] Starting Flutter Desktop App...
start "LUMOS Desktop" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop && C:\src\flutter\bin\flutter.bat run -d windows"

echo.
echo ========================================
echo   All services starting...
echo   API:      http://localhost:8000/docs
echo   AI:       http://localhost:8001/health
echo   Desktop:  Flutter window should appear
echo ========================================
echo.
echo Press any key to close this window...
pause >nul

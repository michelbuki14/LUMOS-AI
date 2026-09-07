@echo off
echo.
echo ========================================
echo   LUMOS AI - Launch Script
echo ========================================
echo.
echo This script will start all LUMOS AI services.
echo.
echo Services to start:
echo   [1] API Server (port 8000)
echo   [2] AI Service (port 8001)
echo   [3] Flutter Desktop App
echo.
echo Press Ctrl+C at any time to stop a service.
echo.
echo Make sure you have:
echo   - Python 3.11+ installed
echo   - Flutter SDK at C:\src\flutter
echo   - Required Python packages installed
echo     (fastapi, uvicorn, sqlalchemy, aiosqlite, etc.)
echo.

set /p CHOICE="Start all services now? (y/n): "
if /i not "%CHOICE%"=="y" (
    echo.
    echo You can start services manually:
    echo.
    echo 1. API Server:
    echo    cd C:\Users\miche\Documents\GitHub\lumos-ai\services\api
    echo    python -m uvicorn lumos.app:app --reload --port 8000
    echo.
    echo 2. AI Service:
    echo    cd C:\Users\miche\Documents\GitHub\lumos-ai\services\ai
    echo    python -m uvicorn lumos.ai.app:app --reload --port 8001
    echo.
    echo 3. Flutter Desktop:
    echo    cd C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop
    echo    C:\src\flutter\bin\flutter.bat run -d windows
    echo.
    pause
    exit /b 0
)

echo.
echo Starting services...
echo.

REM Start API Server in a new window
start "LUMOS API Server" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\services\api && python -m uvicorn lumos.app:app --reload --host 0.0.0.0 --port 8000"

timeout /t 2 /nobreak >nul

REM Start AI Service in a new window  
start "LUMOS AI Service" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\services\ai && python -m uvicorn lumos.ai.app:app --reload --host 0.0.0.0 --port 8001"

timeout /t 2 /nobreak >nul

REM Start Flutter Desktop App in a new window
start "LUMOS Desktop App" cmd /k "cd /d C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop && C:\src\flutter\bin\flutter.bat run -d windows"

echo.
echo All services have been started in separate windows.
echo.
echo API:   http://localhost:8000/docs
echo AI:    http://localhost:8001/health
echo.
pause

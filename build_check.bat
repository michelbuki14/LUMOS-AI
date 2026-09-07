@echo off
echo ========================================
echo   LUMOS AI - Build & Run
echo ========================================
echo.

cd /d C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop

echo Step 1: Getting Flutter dependencies...
echo.
C:\src\flutter\bin\flutter.bat pub get
if %errorlevel% neq 0 (
    echo ERROR: flutter pub get failed
    pause
    exit /b 1
)

echo.
echo Step 2: Running Flutter analyze (checking for errors)...
echo.
C:\src\flutter\bin\flutter.bat analyze --no-fatal-infos --no-fatal-warnings
echo.

echo ========================================
echo   Check the output above for errors
echo ========================================
pause

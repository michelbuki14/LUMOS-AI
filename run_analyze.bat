@echo off
cd /d C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop
echo ========================================
echo   LUMOS AI - Flutter Analysis
echo ========================================
echo.

C:\src\flutter\bin\flutter.bat analyze 2>&1

echo.
echo ========================================
echo   Done. Check above for errors.
echo ========================================
pause

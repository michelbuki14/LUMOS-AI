@echo off
REM Run cargo check for the Rust renderer
cd /d C:\Users\miche\Documents\GitHub\lumos-ai\services\render
echo ========================================
echo   Rust Render Engine - Cargo Check
echo ========================================
echo.

cargo check 2>&1

echo.
echo ========================================
echo   Done. Exit code: %errorlevel%
echo ========================================
pause

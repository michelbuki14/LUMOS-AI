@echo off
SETLOCAL enabledelayedexpansion

echo ========================================
echo   Installing Flutter SDK
echo ========================================

REM Check if already installed
if exist "C:\src\flutter\bin\flutter.bat" (
    echo Flutter already installed at C:\src\flutter
    goto :doctor
)

echo Cloning Flutter stable to C:\src\flutter...
git clone --branch stable --depth 1 https://github.com/flutter/flutter.git C:\src\flutter
if !errorlevel! neq 0 (
    echo ERROR: Git clone failed
    pause
    exit /b 1
)

echo.
:doctor
echo.
echo Running flutter doctor...
echo (This may show missing components - that's OK, we just need the engine)
C:\src\flutter\bin\flutter.bat doctor --verbose

echo.
echo ========================================
echo   Flutter installation complete!
echo ========================================
echo.
echo Add to your PATH for permanent access:
echo   setx PATH "%PATH%;C:\src\flutter\bin"
echo.
echo Or run this script to use Flutter immediately:
echo   C:\src\flutter\bin\flutter.bat <command>
echo.
echo Next steps:
echo   1. cd C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop
echo   2. C:\src\flutter\bin\flutter.bat pub get
echo   3. C:\src\flutter\bin\flutter.bat run -d windows
echo.
pause

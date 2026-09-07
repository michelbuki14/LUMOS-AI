@echo off
cd /d C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop
echo Running Flutter analyze...
C:\src\flutter\bin\flutter.bat analyze --no-fatal-infos --no-fatal-warnings 2>&1 | findstr /i "error" | find /c /v ""
echo.
echo Total errors: 
echo.
C:\src\flutter\bin\flutter.bat analyze --no-fatal-infos --no-fatal-warnings 2>&1 | findstr /i "^  error"
echo.
pause

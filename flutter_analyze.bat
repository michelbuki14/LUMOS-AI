@echo off
echo Running Flutter analysis...
cd /d C:\Users\miche\Documents\GitHub\lumos-ai\apps\desktop
C:\src\flutter\bin\flutter.bat analyze 2>&1 | findstr /i "error\|warning\|info" | find /c /v ""
echo.
echo Done. Check output above for errors.
pause

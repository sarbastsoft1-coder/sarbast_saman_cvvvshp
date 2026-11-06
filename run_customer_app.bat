@echo off
echo ====================================================
echo Starting EarthShop Customer App on Chrome (Web)...
echo Local URL: http://localhost:8080
echo ====================================================
cd /d "%~dp0customer_app"
flutter run -d chrome --web-port=8080
pause

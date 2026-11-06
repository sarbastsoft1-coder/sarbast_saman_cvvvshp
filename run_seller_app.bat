@echo off
echo ====================================================
echo Starting EarthShop Seller App on Chrome (Web)...
echo Local URL: http://localhost:8081
echo ====================================================
cd /d "%~dp0seller_app"
flutter run -d chrome --web-port=8081
pause

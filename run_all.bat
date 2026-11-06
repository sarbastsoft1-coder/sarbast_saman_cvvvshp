@echo off
echo ====================================================
echo Starting EarthShop Ecosystem (Backend + Apps)
echo ====================================================

echo [1/5] Starting Laravel Backend API on Port 8000...
start "EarthShop Backend API" cmd /k "cd /d %~dp0backend && php artisan serve --host=127.0.0.1 --port=8000"

timeout /t 3 /nobreak >nul

echo [2/5] Starting Customer App on Port 8080...
start "EarthShop Customer App" cmd /k "cd /d %~dp0customer_app && flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1"

timeout /t 2 /nobreak >nul

echo [3/5] Starting Seller App on Port 8081...
start "EarthShop Seller App" cmd /k "cd /d %~dp0seller_app && flutter run -d chrome --web-port=8081 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1"

timeout /t 2 /nobreak >nul

echo [4/5] Starting Admin App on Port 8082...
start "EarthShop Admin App" cmd /k "cd /d %~dp0admin_app && flutter run -d chrome --web-port=8082 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1"

timeout /t 2 /nobreak >nul

echo [5/5] Starting Delivery App on Port 8083...
start "EarthShop Delivery App" cmd /k "cd /d %~dp0delivery_app && flutter run -d chrome --web-port=8083 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1"

echo ====================================================
echo All services launched!
echo - Backend API  : http://127.0.0.1:8000/api/v1
echo - Customer App : http://localhost:8080
echo - Seller App   : http://localhost:8081
echo - Admin App    : http://localhost:8082
echo - Delivery App : http://localhost:8083
echo Seeded password for all roles: password
echo ====================================================

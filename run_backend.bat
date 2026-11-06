@echo off
echo ====================================================
echo Starting EarthShop Laravel Backend API Server...
echo Local API URL: http://127.0.0.1:8000
echo ====================================================
cd /d "%~dp0backend"
php artisan serve --host=127.0.0.1 --port=8000
pause

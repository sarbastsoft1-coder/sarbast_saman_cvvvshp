# EarthShop

Multi-app marketplace: Laravel API + Flutter clients (customer, seller, admin, delivery).

## Ports

| Service | URL |
|---------|-----|
| Backend API | http://127.0.0.1:8000 (`/api/v1`) |
| Customer app | http://localhost:8080 |
| Seller app | http://localhost:8081 |
| Admin app | http://localhost:8082 |
| Delivery app | http://localhost:8083 |

Override API base for Flutter:

```bat
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Android emulator: use `http://10.0.2.2:8000/api/v1`.

## Seeded users (password: `password`)

- `admin@earthshop.test`
- `seller@earthshop.test`
- `customer@earthshop.test`
- `driver@earthshop.test`

## Launch

Stop any other process on port 8000 first (a Node Express stub may steal it). Then:

```bat
run_backend.bat
run_all.bat
```

Or individually:

```bat
run_backend.bat
cd customer_app && flutter run -d chrome --web-port=8080
cd seller_app && flutter run -d chrome --web-port=8081
cd admin_app && flutter run -d chrome --web-port=8082
cd delivery_app && flutter run -d chrome --web-port=8083
```

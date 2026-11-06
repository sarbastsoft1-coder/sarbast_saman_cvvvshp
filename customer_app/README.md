# Boutique customer app

Kurdish (Sorani) Flutter storefront with responsive layouts and device-local shopping state.

```powershell
flutter pub get
flutter run -d chrome --web-port=8080
```

```powershell
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

The active app is under `lib/boutique/`. This is a local demo: checkout does not charge money or send an order to a seller. See [CUSTOMER_REVIEW.md](CUSTOMER_REVIEW.md) for completed work, validation, asset provenance, and the remaining production integrations.

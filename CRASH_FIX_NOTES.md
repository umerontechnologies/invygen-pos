# Invygen Android crash fix

This build fixes the startup crash caused by an invalid SQLite CREATE TABLE statement in `lib/core/database/app_database.dart`.

After applying this fix, uninstall the old test app from the phone or clear its app data before installing the new APK, so the local SQLite database is recreated cleanly.

Commands:

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

APK output:

`build/app/outputs/flutter-apk/app-release.apk`

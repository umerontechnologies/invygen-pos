# Invygen Android Offline - Production Upgrade Pass

This package upgrades the starter app into a more complete offline POS/inventory app.

## Added modules/features
- Professional POS cart screen with customer/retailer selection, search/barcode text input, quantity controls, discount, payment method and invoice completion.
- PDF receipt/invoice printing and sharing through Android print/share actions.
- Pending/delivered/cancelled orders with PDF print/share and stock deduction on delivery.
- Supplier-product relationship: each product can be linked to a supplier.
- Supplier contact actions for low/out-of-stock products.
- Purchases / Stock In module to increase product stock from suppliers.
- Customer and retailer management with balances and payment receive action.
- Retailer-specific product price screen.
- Editable business profile: company, owner, country, currency, tax details, invoice prefix and receipt footer.
- Local profile screen.
- Backup/export and restore using offline JSON backup files.
- Reports: sales summary, customer dues, inventory value, low-stock list, top-selling products.
- Language foundation with English, Spanish, French and Arabic for main navigation/settings labels.
- Custom Invygen app icon assets and flutter_launcher_icons config.

## How to apply to your existing Flutter project
1. Backup your current Flutter project.
2. Copy `pubspec.yaml`, `lib/`, and `assets/` from this package into your project.
3. Run:
   ```bash
   flutter clean
   flutter pub get
   dart run flutter_launcher_icons
   flutter run
   flutter build apk --release
   flutter build appbundle --release
   ```

## Android package name
Before Play Store upload, make sure `android/app/build.gradle.kts` uses a real package name, not `com.example`:

```kotlin
namespace = "com.umeron.invygen"
applicationId = "com.umeron.invygen"
```

## Android permissions
For `url_launcher`, `printing`, `share_plus`, and file picker, Flutter plugins usually add required manifest entries. If your Android build asks for package visibility, add tel/mail queries to `AndroidManifest.xml`.


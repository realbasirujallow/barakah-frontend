# Barakah — Islamic Finance Tracker (Flutter Mobile)

A Flutter mobile app for halal-conscious personal finance management. Tracks assets, debts, budgets, transactions, zakat, sadaqah, waqf, wasiyyah, and more.

## Prerequisites

- Flutter SDK ^3.11.0 (Dart ^3.11.0)
- Android Studio / Xcode for emulator/device
- Backend running at `https://api.trybarakah.com` (or local instance)

## Getting Started

```bash
flutter pub get
flutter run
```

## Build-Time API URL

The app connects to `https://api.trybarakah.com` by default. Override at build time with `--dart-define`:

```bash
# Local development (use your machine's LAN IP, not localhost)
flutter run --dart-define=API_URL=http://192.168.1.x:8080

# Debug APK pointing to local backend
flutter build apk --debug --dart-define=API_URL=http://192.168.1.x:8080

# Release APK (uses default production URL)
flutter build apk --release

# Release APK with custom API URL
flutter build apk --release --dart-define=API_URL=https://your-api.example.com
```

> **Note:** Android emulator uses `10.0.2.2` to reach the host machine's localhost.
> So for emulator testing: `--dart-define=API_URL=http://10.0.2.2:8080`

## Project Structure

```
lib/
  main.dart            # App entry point with global error handling
  models/              # Data models (Asset, Transaction, etc.)
  screens/             # All UI screens
  services/            # API service, auth service, biometric, cache
  theme/               # App theme constants
  widgets/             # Reusable widget components
```

## Key Features

- **Dashboard** — Net worth overview, zakat indicator, quick actions
- **Transactions** — Income/expense tracking with categories, recurring support
- **Assets** — Multi-type asset management (cash, stocks, crypto, real estate, retirement)
- **Budgets** — Monthly budget tracking per category
- **Debt Tracker** — Riba detection, payment tracking, Islamic alternatives
- **Savings Goals** — Goal-based savings with progress tracking
- **Zakat Calculator** — Nisab threshold, hawl tracking, zakatable wealth breakdown
- **Sadaqah & Waqf** — Charity and endowment tracking
- **Wasiyyah** — Islamic will / beneficiary management
- **Halal Screener** — Stock halal compliance checking
- **Shared Finances** — Family/group finance management
- **Investments** — Portfolio tracking with gain/loss
- **Biometric Auth** — Fingerprint/face login support
- **Credit Score** — Credit score tracking and tips

## Running Tests

```bash
flutter test
```

## Analyze

```bash
flutter analyze   # Should report 0 issues
```

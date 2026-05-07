# DocuLens

A privacy-first, offline document vault for Android. Scan your ID cards and important documents, extract key details automatically, and store everything securely on your device — no cloud, no servers, no data leaving your phone.

## What it does

- Scan any ID card or document using your camera
- Automatically extracts Name, Date of Birth, and Gender using on-device OCR
- Review extracted fields with confidence indicators — edit anything that's wrong
- Save documents with their image to a permanent local vault
- View and edit saved documents anytime

## Privacy

Everything stays on your device. No internet connection is required after setup. Images are stored in your app's private sandbox and are never accessible to other apps.

## Screenshots

_Coming soon_

##  Project Structure

```bash
lib/
│   main.dart
│
├── models
│   ├── document_data.dart
│   └── document_record.dart
│
├── screens
│   ├── document_detail_screen.dart
│   ├── home_screen.dart
│   ├── scanner_screen.dart
│   └── settings_screen.dart
│
├── services
│   ├── database_service.dart
│   ├── ocr_service.dart
│   └── telemetry_service.dart
│
├── theme
│   └── app_theme.dart
│
└── widgets
    ├── confidence_indicator.dart
    ├── editable_field_card.dart
    └── edit_field_dialog.dart
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android device or emulator (API 21+)
- Firebase project with `google-services.json` placed in `android/app/`

### Setup

```bash
git clone https://github.com/yourusername/doculens.git
cd doculens
flutter pub get
flutter run
```

> **Note:** You will need to add your own `google-services.json` from the Firebase Console. This file is not included in the repo for security reasons.

## Tech Stack

- **Flutter** — UI framework
- **ML Kit** — on-device OCR and entity extraction
- **SQLite (sqflite)** — local database
- **Firebase Analytics & Crashlytics** — anonymous usage and crash reporting (can be disabled in Settings)

## Planned Features

- Search across saved documents
- Support for more document types and fields
- Export documents as PDF
- Biometric lock for the vault
- Bulk document management

## License

MIT

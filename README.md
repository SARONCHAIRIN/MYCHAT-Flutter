# MYCHAT Flutter

Flutter + Riverpod + Dio + secure storage + Firebase Messaging + STOMP client.

## Setup

Use a compatible Flutter SDK (Dart >=3.11 per `pubspec.yaml`), Android SDK or Xcode, and a configured Firebase project.

```bash
flutter doctor -v
flutter pub get
flutter run -d R5CXB2MNAWR --dart-define=API_BASE_URL=https://mychat-umla.onrender.com
```

Use a staging backend for QA. Android setup: `android/`; iOS setup: `ios/`. Ensure Firebase platform files and notification permissions match the installed app IDs.

## Tests

```bash
flutter test
flutter test --coverage
flutter test integration_test/auth_ui_smoke_test.dart -d R5CXB2MNAWR
bash tool/quality_gate.sh
```

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [API integration](docs/API_INTEGRATION.md)
- [Testing](docs/TESTING.md)
- [Release](docs/RELEASE.md)
- [Final QA checklist](docs/PHASE_32_QA_CHECKLIST.md)
- [Delivery report](FINAL_IMPLEMENTATION_REPORT.md)

**Do not publish:** release identifiers, signing, controlled-backend E2E and physical-device QA are not yet verified.

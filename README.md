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

## Setup (added)
`flutter pub get`, then `flutter run --dart-define=API_BASE_URL=https://mychat-umla.onrender.com`.
See KNOWN_LIMITATIONS.md before testing image messages: the backend does not currently serve `/uploads`.

## Voice messages

The chat composer includes a microphone button. Tap once to start recording and tap
the stop button to upload the recording. The upload uses the authenticated
`POST /api/v1/voice-messages` endpoint with multipart fields `conversationId`,
`durationSeconds`, and `file`. Voice bubbles stream from
`GET /api/v1/voice-messages/{messageId}/audio`, using the saved Bearer token.
The audio player supports play/pause and seeking; the backend's HTTP Range support
is used by the player when seeking.

New dependencies: `record`, `just_audio`, and `path_provider`.

After updating this project, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=https://mychat-umla.onrender.com
```

Android declares `RECORD_AUDIO` and requires minSdk 23 for the recording plugin.
iOS declares `NSMicrophoneUsageDescription`. Test microphone permission and playback
on a physical device before release.

## Voice message playback troubleshooting

- Run with the backend origin, not a nested API path:
  `flutter run --dart-define=API_BASE_URL=https://mychat-umla.onrender.com`
- Voice playback logs the exact audio URL. A `404` means the backend could not find the message/audio for that request; verify that the URL contains the expected numeric message ID and test the same ID in Swagger while signed in as a conversation participant.
- If existing images and avatars at `/uploads/...` also return `404`, the backend's uploaded files may be missing from its deployment filesystem. Flutter cannot restore those files; configure the backend to use persistent storage (for example the existing R2 storage implementation) and re-upload missing media.

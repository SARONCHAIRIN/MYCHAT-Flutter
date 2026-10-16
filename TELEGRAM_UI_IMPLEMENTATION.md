# MYCHAT — Telegram-inspired native Flutter UI

This is a **Telegram-inspired visual redesign**, not Telegram source code or a Telegram API client.

## Changes
- Native Dart/Flutter Material 3 theme: Telegram-style blue (#2481CC), airy white chat list, muted secondary text, rounded search field and filter chips.
- Telegram-style home app bar, hamburger navigation drawer, bottom tabs and entry points to existing Settings and Blocked Users screens.
- Shared `TelegramAvatar` widget displays API-provided `avatarUrl` when valid; falls back to initials/group icon.
- Conversation list and people list use existing real repository data and preserve their navigation/action handlers.
- Chat view uses incoming white and outgoing soft-green bubbles, blue read checks and a muted chat wallpaper-style background.
- Existing Dio/Riverpod/auth/session/FCM/message repository methods are retained.

## Important limitations
- Flutter SDK was not installed in this generation environment: `flutter analyze`, `flutter test`, and device run were **not executed**.
- No authenticated live API smoke test was performed; backend endpoints are **not verified**.
- Existing chat implementation uses REST polling as fallback. Real-time STOMP delivery is **not verified** and is not advertised as fully working.
- Existing avatar edit action accepts an image URL; gallery upload requires a supported upload workflow.
- End-to-end encryption is not proven by the API contract; UI does not claim E2EE.
- The full API contract includes features beyond this visual pass. Not all endpoints have newly designed UI entry points.

## Local verification
```bash
flutter pub get
flutter analyze
flutter test
flutter run -d R5CXB2MNAWR
```

For a safe merge, compare changed files before copying. Keep the original Git repo and Firebase configuration.

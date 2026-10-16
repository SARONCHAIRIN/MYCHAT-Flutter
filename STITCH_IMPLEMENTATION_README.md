# MYCHAT Stitch Flutter adaptation (2026-10-15)

## Source of truth
- `design_reference/`: the six supplied Stitch HTML + PNG screens and Kinetic Slate DESIGN.md.
- `lib/features/ui/screens.dart`: registration, login, chats inbox, people search, navigation and profile.
- `lib/features/messages/chat_screen.dart`: conversation UI; existing REST message actions preserved.
- `lib/core/theme/stitch_theme.dart`: Stitch color and spacing theme.

## Real API
The existing Dio client defaults to `https://mychat-umla.onrender.com`, with an override via `--dart-define=API_BASE_URL=...`.
Existing auth, conversation, user, message, notifications, device registration and Firebase code has not been replaced with mock data.
People -> Start Chat invokes `POST /api/v1/conversations` and opens the returned conversation.

## Important limitations
- Stitch export includes **six** screen designs, not designs for every feature of the application.
- This is a Flutter-native adaptation, **not a verified pixel-perfect reproduction**.
- No Flutter SDK is installed in the artifact-generation environment; `flutter analyze`, `flutter test` and device runs must be performed locally.
- The app's existing realtime fallback polls REST every five seconds. A production WebSocket/STOMP connection is not verified by this change.
- Live backend calls were not performed, and API response compatibility is not verified against a running server.
- Do not overwrite your git working tree before backing it up. Merge changed files selectively and review `git diff`.

## Run
```
flutter pub get
flutter analyze
flutter test
flutter run -d R5CXB2MNAWR --dart-define=API_BASE_URL=https://mychat-umla.onrender.com
```

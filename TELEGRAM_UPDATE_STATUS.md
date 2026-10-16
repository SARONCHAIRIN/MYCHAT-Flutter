# MYCHAT Telegram-style Flutter update — 2026-10-15

## Changes made in this ZIP
- Native Flutter message long-press menu with seven emoji reactions, Reply, Copy, Send to another chat, Pin, Edit/Delete (own messages), and reaction viewing.
- Conversation header resolves conversation metadata using `GET /api/v1/conversations/{id}` and attempts to resolve the direct-chat peer through `GET /api/v1/conversations/{id}/members` and `GET /api/v1/users/{id}`. Avatar uses the real `avatarUrl` when supplied.
- Forward-like action sends **plain text** through the existing send-message API, since the provided Swagger endpoint list does not include a forward-message endpoint. It does not preserve attribution or attachment.
- Existing Dio, auth, messages, notification, settings, blocking and group repositories preserved.

## Important limits
- **Not all endpoints are verified end-to-end.** An endpoint being present in the repository is not proof that its UI flow works.
- **Flutter SDK unavailable in this execution environment**: `flutter analyze`, `flutter test`, and device tests were not run.
- The chat still uses a 5-second REST fallback; WebSocket/STOMP real-time delivery must be verified on two devices.
- User avatars only show when the backend returns a valid reachable `avatarUrl`. `PATCH /users/me/avatar` expects a URL, not raw image bytes.
- This is a focused improvement of the existing Flutter project, not a complete Telegram clone.

## Verify locally
```sh
flutter pub get
dart format lib
flutter analyze
flutter test
flutter run -d R5CXB2MNAWR
```

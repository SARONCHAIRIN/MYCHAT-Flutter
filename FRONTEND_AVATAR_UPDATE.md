# MYCHAT Flutter – Backend Avatar Upload Integration

Updated from the locally available MYCHAT-Telegram-Professional-Stability-2026-10-18.zip snapshot (not a verified live GitHub checkout).

- Profile photo camera button opens native image/file picker, no URL dialog.
- JPG/JPEG, PNG, WebP, max 5 MB; sends PATCH /api/v1/users/me/avatar with multipart field `file`.
- Reuses existing authenticated Dio client, reloads /users/me and shows upload progress.
- Existing file_picker dependency reused, no pubspec change.

Run `flutter pub get`, `flutter analyze`, `flutter run` locally. Flutter SDK is not installed in this environment; compilation not verified.

IMPORTANT: backend must actually serve /uploads/... as image bytes and retain uploaded files on persistent storage; otherwise profile photos will still fail to render after upload, especially after a Render restart.

# MYCHAT Flutter authenticated image loading

- `UserAvatar` now includes the stored Bearer token when requesting private `/uploads/` avatar URLs. All `TelegramAvatar` uses inherit this change.
- `ConversationAvatar` (conversation list) also sends the Bearer token.
- Chat message images already sent the Bearer token and use `attachments[].fileUrl` from message history.
- Profile upload invalidates `authProvider` so profile views refresh.

## Test

Run `flutter pub get`, `flutter analyze`, `flutter run`. Test profile photo in Profile, Settings, Contacts, conversation list, and chat header; then send an image, exit chat, and reopen.

Backend must serve GET `/uploads/{filename}` to authorized users and preserve image bytes in persistent storage. Old missing files that return 404 cannot be recovered by frontend changes. A 401 with an attached token means the backend access policy/token validity must be checked. Flutter SDK was unavailable in the patch environment, so compilation/device tests were not run.

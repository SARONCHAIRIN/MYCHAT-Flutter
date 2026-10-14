# MYCHAT Flutter — Notification review (2026-10-14)

## Source
Reviewed uploaded `MYCHAT-Flutter-dev_rin(3).zip`. This is a source archive, not a live device build or Git checkout.

## Verified in source
- `MaterialApp` has `NotificationRouter.navigatorKey`.
- `ChatScreen` accepts `Object conversationId` and loads message history on initialization.
- FCM `onMessageOpenedApp` listener appears once in the service.
- FCM notification type is `message:new` with `conversationId` and `messageId`.
- Device registration uses `POST /api/v1/devices` via Dio.

## Additional changes in this archive
- Queue draining is scheduled after the current frame when authentication becomes ready.
- Explicit logout clears pending notification and last-tap deduplication state to avoid opening another account's queued conversation.
- Tidied login notification initializer block.

## Still needs device verification
1. `flutter pub get && flutter analyze && flutter test`.
2. Cold-start notification tap while already signed in.
3. Notification tap from background and duplicate tap handling.
4. Login after tapping a notification while signed out.
5. Ensure notification registration works after token rotation and app restarts.
6. Message-specific scroll/highlight is not implemented; only the conversation is opened.

## Notes
- No Git push was performed.
- FCM registration currently uses a generic Android device label; other platform support is not yet implemented.
- Push notification display in foreground and real-time message refresh are separate tasks.

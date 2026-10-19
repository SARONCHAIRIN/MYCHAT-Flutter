# MYCHAT Flutter frontend update — 2026-10-19

## Implemented in this archive
- HTTP 401 auto-refresh using a single shared refresh request, refresh-token rotation, and one retry of the original Dio request. Transient failures do not wipe tokens.
- Theme-aware conversation/contact surfaces and text; existing light/dark/system selector retained.
- Extended Khmer UI dictionary, translated key navigation, settings and selected screen labels; other hard-coded strings remain and require localization coverage. Settings -> Color theme opens the actual local theme/language preferences instead of a disconnected server setting.
- Notification history parser supports nested list/page envelopes; device-local FCM cache (up to 100 messages, per JWT user subject) complements server history; manual pull-to-refresh and 30-second foreground refresh retained. Server-side persisted notifications remain necessary for multi-device history.
- Foreground Android notification large icon: downloads sender avatar when FCM data includes `senderAvatarUrl`, `senderAvatar`, or `avatarUrl`. Private avatar URLs use stored JWT. Fallback to launcher icon if absent/unavailable.

## Still requires backend changes / validation
- Background/terminated Android notification avatar: FCM notification tray is system-rendered. The backend must send suitable image data, or Android must implement custom background notification rendering; this archive only updates foreground notifications.
- The backend must persist notification history and return it through GET /api/v1/notifications. If this returns [], Flutter cannot recreate history from prior push banners.
- Sender avatar field must be present in FCM data payload; otherwise Flutter cannot identify the sender image.
- Full-app localization has NOT been completed; translations dictionary covers common UI but not every string in every screen.
- Flutter SDK is unavailable in this environment; run flutter analyze, flutter test, and Android device checks before releasing.

## Testing
flutter pub get
flutter analyze
flutter test
flutter run

Test dark/light chats, contacts and profile; Khmer/English; 401 expiry and rotated refresh token; foreground/background FCM; notifications endpoint response shape.

# MYCHAT Flutter update (2026-10-19)

## Implemented in this ZIP
- App-wide light/dark/system theme selector persisted via FlutterSecureStorage.
- English/Khmer language preference persisted and used in navigation labels, notifications empty state, and appearance settings. **Partial localization only**; other screens retain existing English strings.
- Appearance & language settings accessible from home drawer.
- Group conversation header displays actual member count from conversation members (when accessible).
- Notifications list parsing now accepts API envelopes with `notifications`, `content`, or `items` arrays as well as bare arrays.
- Notifications screen refreshes every 30 seconds while mounted, in addition to manual refresh.
- Notification rows display sender avatar when the API returns `senderAvatarUrl`, `senderAvatar`, `avatarUrl`, or `avatar_url`.

## Backend requirements / limitations
- The backend MUST persist notification records for GET /api/v1/notifications. Flutter cannot reconstruct complete historical notifications from FCM pushes alone. If the API returns an empty list, investigate backend event persistence, recipient IDs, and response shape.
- The backend FCM payload must contain sender name, message preview and avatar URL for personalized phone notifications. The frontend cannot inject another user's avatar into an already delivered background FCM notification. Foreground banners currently display backend-supplied title/body; avatar-as-large-icon in the OS banner is NOT implemented.
- Group member counts require permission to call GET /api/v1/conversations/{id}/members or a `members` list in the conversation detail.
- Full app-wide Khmer localization and a robust background/terminated Android avatar notification require further work and device testing.

## Validation
- Flutter and Dart SDK are not installed in the execution environment; `flutter analyze`, `flutter test`, and Android runtime verification were NOT run. Run them locally before release.

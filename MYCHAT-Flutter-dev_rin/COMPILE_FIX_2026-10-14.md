# MYCHAT compile fix

Fixed `notification_router.dart`: `openData()` previously referred to undefined `message` when queuing notification taps. It now stores the notification data map and optional tap ID, then replays through `openData()` after authentication. This supports both FCM `RemoteMessage` taps and local-notification payload taps.

This is a targeted compile fix. `flutter analyze`, `flutter test`, and Android device builds must be run locally; Flutter SDK is not installed in the packaging environment. The 33 lint issues were not addressed by this patch.

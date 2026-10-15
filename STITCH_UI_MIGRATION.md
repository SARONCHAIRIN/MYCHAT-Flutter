# MYCHAT Stitch UI migration (API-preserving)

This package is an **overlay on the previously uploaded Flutter source**, not a verified checkout of commit `86497ad`. Preserve your local Git history; apply via preview first.

Updated: `lib/main.dart`, `lib/core/theme/stitch_theme.dart` (new), `lib/features/ui/screens.dart`, `lib/features/messages/chat_screen.dart`.

Unchanged: Dio API endpoints, repositories, auth state and login/register requests, Riverpod providers, token storage, FCM, notification navigation, message polling, sending, editing, reactions, attachments, and other business logic.

Visuals: Indigo/light Stitch tokens; splash/loading branding; authentication header/form treatment; bottom navigation; conversation/people avatars; message bubbles and composer. This is a **first-pass native Flutter adaptation**, not pixel-perfect fidelity to all six supplied Stitch screens. No HTML/WebView is used.

Note: Outgoing bubble alignment relies on existing message JSON flags (`isMine`, `mine`, `isOwn`). If backend does not return those flags, messages default to incoming alignment until current-user comparison is wired in. Do not infer ownership from sender display names.

Verification: Run `flutter pub get`, `dart format lib`, `flutter analyze`, `flutter test`, and a real-device smoke test. The runtime here has no Flutter SDK, so build/test success is **not claimed**.

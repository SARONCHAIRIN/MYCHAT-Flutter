# Telegram-inspired Message Menu Update

- Replaced the oversized `showModalBottomSheet` action list with a dark, rounded, position-anchored Flutter `showMenu` popup.
- Emoji reaction strip at the top; actions: Reply, Copy, Forward (send text as new message), Pin, Edit/Delete (own messages), Reactions.
- Long-press opens the menu near the pressed message using `onLongPressStart`.
- Preserves existing Riverpod repositories and MYCHAT API calls. No HTML/WebView.
- Forward is text-only; backend API list does not define forward attribution.
- This changes the chat menu only; other app screens are unchanged.
- Flutter SDK is unavailable in this environment, so compile and device tests have NOT been run.

Run locally: `flutter pub get && dart format lib/features/messages/chat_screen.dart && flutter analyze && flutter test`.

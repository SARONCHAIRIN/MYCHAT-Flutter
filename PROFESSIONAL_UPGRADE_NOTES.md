# MYCHAT professional polish — 2026-10-15

Changes to existing Flutter application:
- Direct conversation header now uses the actual `members[].userId` instead of confusing membership record `id` with user ID; uses embedded members first, reducing API calls.
- Shared TelegramAvatar displays an initial/group icon when a URL is missing or returns invalid image bytes, rather than relying on NetworkImage exceptions.
- Incoming message avatar uses conversation peer's avatar instead of generic person icon.
- Reactions appear under message text/time in the message bubble. Tapping an existing chip toggles own reaction where individual user IDs are supplied by the backend.
- Attachment renderer recognizes storageUrl and image extensions in filename when MIME is missing.
- Compact emoji menu hit targets enabled; menu fits narrow devices better.

Backend caveats:
- Avatar links like share.google and Google redirect URLs return HTML, not image bytes. Set a real publicly accessible image URL via PATCH /api/v1/users/me/avatar.
- Upload endpoint requires an existing messageId; a full Telegram-style media-only send requires verifying the backend upload/message schema.
- No live Flutter SDK available in this environment; run `flutter analyze`, `flutter test` and device tests before release.

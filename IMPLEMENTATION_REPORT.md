# IMPLEMENTATION_REPORT

Changed/added files (all unverified by compiler — see TEST_REPORT.md):

- `lib/core/network/api.dart` – exports `apiBaseUrl`.
- `lib/core/widgets/user_avatar.dart` – **new** `UserAvatar`: URL validation (http/https, relative paths resolved,
  known non-image share hosts rejected), loading placeholder, initials fallback, failed URLs not retried.
- `lib/features/ui/screens.dart` – `TelegramAvatar` delegates to `UserAvatar`; profile avatar no longer uses
  `NetworkImage`; conversation list uses the resolver; drawer shows real name/@username/avatar and a
  confirmed, double-tap-safe **Log out** (calls `AuthController.logout`, then returns to root).
- `lib/features/conversations/conversation_display.dart` – **new** resolver (DIRECT → other member, never own avatar).
- `lib/features/reactions/reaction_summary.dart` – **new** aggregation/dedupe/own-highlight/toggle logic.
- `lib/features/uploads/attachment.dart` – **new** upload contract helpers (MIME, 25 MB check, URL resolution, parsing).
- `lib/features/messages/message_repository.dart` – upload sends explicit Content-Type; `sendAttachmentMessage`.
- `lib/features/messages/chat_screen.dart` – attach → preview/caption dialog → create IMAGE/FILE message → upload with
  progress and Retry; local image copy + authenticated network image + pinch-zoom viewer; reaction chips highlight own;
  Unpin; STOMP subscription to `/topic/conversations/{id}` (`message:*`, `reaction:*`) with polling fallback;
  actions no longer scroll to bottom.
- Tests: `conversation_display_test`, `reaction_summary_test`, `attachment_test`, `user_avatar_test`.

Acceptance status: see TEST_REPORT.md (everything runtime-related is NOT TESTED).

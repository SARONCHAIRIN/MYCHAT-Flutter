# API_COVERAGE

Source: backend controllers/DTOs + `docs/FLUTTER_API_HANDOFF.md`. Status is about code written,
not runtime verification. "Test" = unit test in repo; nothing was run against the live server.

| Endpoint | Repository method | Feature | Status | Test |
|---|---|---|---|---|
| POST /auth/login, /register, /refresh | AuthRepository | Auth | Existing | Existing unit tests (not re-run) |
| POST /auth/logout `{refreshToken}` | LogoutService.revoke | Drawer → Log out (new entry point) | Wired | Existing test (not re-run) |
| GET /auth/me, /users/me | AuthRepository.me | Drawer, Profile | Existing | — |
| PATCH /users/me, /users/me/avatar `{avatarUrl}` | UserRepository | Profile | Existing | — |
| GET /users, /users/{id}, /users/search | UserRepository | People | Existing | — |
| /conversations (+ members, role) | ConversationRepository | Chats, details | Existing; list now uses display resolver | resolver tests |
| GET/POST /conversations/{id}/messages | MessageRepository.history/send | Chat | Existing | merge test exists |
| POST message `type=IMAGE|FILE` + POST /uploads | sendAttachmentMessage + upload | Chat attach | **New flow** | mime/validation tests |
| PATCH/DELETE /messages/{id} | edit/delete | Chat menu | Existing | — |
| GET/POST/DELETE reactions | reactions/react/unreact | Chat | Existing; chips use summarizer + highlight | summary tests |
| GET/POST/DELETE pins | pins/pin/unpin | Chat | Unpin added to menu | — |
| POST /messages/{id}/read, /delivered | read/delivered | — | Repository only; not called from UI | — |
| GET/PATCH /settings | settings.dart | Settings | Existing | — |
| blocked users, notifications, devices, reports | existing files | Respective screens | Existing | — |
| STOMP /ws, /topic/conversations/{id} | RealtimeService | Chat | **Wired** (message/reaction events) | none |

Not verified against the live OpenAPI JSON (unreachable). Endpoints not listed were not modified.

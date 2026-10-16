# PROJECT_AUDIT

Scope: static read of `lib/`, `test/`, `pubspec.yaml`, plus the backend source
(`SARONCHAIRIN/MYCHAT`, cloned) as the API contract. The live OpenAPI URL
(`mychat-umla.onrender.com`) was NOT reachable from the audit sandbox, so the
contract below comes from backend controllers/DTOs and `docs/FLUTTER_API_HANDOFF.md`.

## Architecture
Flutter + Riverpod + Dio + flutter_secure_storage. Feature folders under `lib/features`
(auth, messages, notifications, settings, safety, data, ui). `ui/screens.dart` (~650 lines)
holds Home, Auth, Profile, People, Conversations; `messages/chat_screen.dart` (~850 lines)
holds chat and pins. Auth gating is done in `main.dart` via `authProvider`.

## Already working (read from code, not run)
Login/register/refresh/logout repository code, FCM init, drawer on Home, anchored message
menu with emoji strip, per-message reaction fetch, pins list, polling every 5 s, settings, blocked users.

## Defects found
1. **Image sending** – composer attached the file to the *last message in the list* (`attach(lastId)`),
   not to a new message; the backend only allows attaching to your own message.
2. **Upload rejected** – multipart `file` had no explicit Content-Type; backend rejects missing/unsupported types.
3. **IMAGE message needs non-blank `content`** – backend validation; client never created an IMAGE message.
4. **Relative `fileUrl`** (`/uploads/<uuid>.ext`) was passed straight to `Image.network`.
5. **Direct chat title/avatar** – list used `c['name']`, which is null for DIRECT chats.
6. **"Invalid image data"** – profile screen used `NetworkImage` as `backgroundImage` (no error handling).
7. **Logout was never reachable from the UI** (`AuthController.logout` had no caller).
8. **Drawer header was static** (no real user, no avatar).
9. **Reactions** were fetched once per message and never refreshed for other users; own reaction not highlighted.
10. **Scroll jump** – every action called `load()` which scrolled to bottom.
11. **No STOMP wiring** – `RealtimeService` existed but the chat only polled.
12. No Unpin action in the message menu.

## Security notes
Tokens are in secure storage and cleared on logout; no tokens logged. Refresh-token rotation on
401 is NOT implemented in the Dio interceptor (see KNOWN_LIMITATIONS). `google-services.json` and
`firebase_options.dart` are committed (normal for client config).

## Backend facts that constrain the app
See KNOWN_LIMITATIONS.md (attachments not returned in history; `/uploads/**` not served; no reactions in message payload).

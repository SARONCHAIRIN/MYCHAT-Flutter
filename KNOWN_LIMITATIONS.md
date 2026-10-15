# KNOWN_LIMITATIONS

## Backend (confirmed in its source/docs)
- **Attachments are not part of message history.** `MessageResponse` has no attachment field and no
  endpoint lists attachments, so an uploaded image cannot be re-displayed after reopening the chat
  from server data alone. The app keeps the sender's local file for the current session only.
- **`/uploads/**` is not served** by the Spring app (404/401 per handoff §6.3). Image URLs only render
  if a reverse proxy/CDN serves them. Recipients will see "Image unavailable" until the backend fixes this.
- **Reactions are not in `MessageResponse`**; the app needs one GET per message (cached; refreshed by WS events).
- `PATCH /users/me/avatar` takes only a URL; there is no endpoint to upload a profile image. The profile
  image picker therefore still needs an externally hosted URL. `/uploads` cannot be used (needs a messageId).
- No native forward endpoint (`forwardedFromId` exists on message create but is not used); forward is a text copy.
- Clients cannot send over STOMP except typing events; the app uses REST for all actions.

## Client
- Realtime: no token-expiry reconnect and no typing/presence/unread handling; polling remains as fallback.
- Group incoming bubbles show the group avatar, not the individual sender's.
- Request-level 401 → refresh-token retry is not implemented in the Dio interceptor.
- Attach button is image/file only; no camera, no voice, no emoji picker.
- Full Telegram redesign of every screen, drawer extras (New Group/Saved Messages), and
  the shared design-token/widget library from the brief were NOT done; only the items in IMPLEMENTATION_REPORT.md.

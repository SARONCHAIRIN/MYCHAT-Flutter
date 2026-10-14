# MYCHAT Phase 15–22 review (2026-10-14)

## Changes implemented
- Foreground Android notification banner using flutter_local_notifications and an Android high-importance channel. Local taps route through NotificationRouter.openData; no FCM token printed.
- ChatScreen periodically fetches newest messages every 5 seconds while visible, merges by ID, retains existing messages on transient failures, and cancels timer on dispose. **This is a polling fallback, not true WebSocket real-time.**
- Removed full notification data from two debug logs.

## Phase 15–21 status
- Phase 15 settings: existing implementation; API enum and theme synchronization still require verification.
- Phase 16 blocking: existing blocked-list/unblock; block action entrypoint still requires verification.
- Phase 17 notifications: existing list/actions; unread badge and API response contract still require verification.
- Phase 18 FCM: foreground Android banner implemented, background and terminated-state tests pending.
- Phase 19 reporting: existing form; backend enums and payload contract need verification.
- Phase 20 UX: partial; full-screen audit pending.
- Phase 21 offline: preserves loaded messages on refresh failure; **no persistent offline cache or queued sends**. WebSocket reconnect not implemented.

## Phase 22 security review — started, not completed
- Token storage uses flutter_secure_storage; inspect auth interceptor and refresh behavior with backend.
- Do not embed secrets in mobile binaries. Check Firebase configs for accidental service-account/private key commits.
- Check deep-link authorization server-side, notification conversation membership, attachment size/MIME validation, and token expiry/logout behavior.
- WebSocket auth remains unverified. The included STOMP service is not wired to ChatScreen because backend destination/handshake contract is unknown.
- Full payload logging for FCM tap removed. Audit remaining logs for sensitive fields.

## Testing required on developer Mac
```sh
cd ~/Downloads/mychat-frontend
flutter pub get
dart format lib
flutter analyze
flutter test
flutter run -d R5CXB2MNAWR
```
Test foreground banner, tapping it, background/cold-start navigation, receive while chat open, 5-second update, offline refresh, login/logout, and notification permission on Android 13+.

**Not claimed:** Phase 15–21 complete; Phase 22 complete; genuine real-time WebSocket; offline message queue; passing Flutter tests; Git push.

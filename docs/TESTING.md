# Phase 26–28 / 32 testing

## Automated

```bash
flutter pub get
flutter test test/phase26_auth_widget_test.dart
flutter test --coverage
flutter test integration_test/auth_ui_smoke_test.dart -d R5CXB2MNAWR
bash tool/quality_gate.sh
```

The widget and integration tests cover **offline auth UI validation only**; they do not prove login, backend availability, WebSocket, or FCM.

## Controlled backend E2E manual sequence

Use two non-production test accounts and a staging backend. Record pass/fail, date, device, backend build and evidence for each:

1. Register -> login -> session restore -> refresh -> logout (verify server token revocation).
2. Search second user -> create direct conversation -> send -> receive without manual refresh -> react -> mark read -> edit -> pin.
3. Update profile/settings; reopen and confirm persistence.
4. Test invalid credentials, duplicate registration, expired tokens, backend unavailable, offline->online, WebSocket reconnect.
5. On Samsung SM A556E: keyboard, SafeArea, back navigation, file picker/upload, notification permission, foreground/background FCM, background/resume, slow network, rotation and theme.
6. Repeat on iOS hardware when available.

**Do not mark complete** until each step is executed and recorded. Do not put test credentials or FCM tokens in reports.

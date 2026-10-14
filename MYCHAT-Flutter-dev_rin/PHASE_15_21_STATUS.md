# MYCHAT Flutter Phase 15–21 implementation status

Baseline: previous Phase 8–14 progress ZIP. The known missing-parenthesis ChatScreen error was corrected in this package.

| Phase | Included | Remaining |
|---|---|---|
| 15 Settings | GET/PATCH repository, Riverpod controller, loading/error/retry, notification switches, LIGHT/DARK controls | Backend enum verification, global MaterialApp theme binding, Stitch fidelity |
| 16 Blocking | GET blocked users, unblock with confirmation, refresh | Block action entrypoint in user profile, backend contract tests |
| 17 Notifications | paged list, mark read, read all, delete, retry, refresh | unread badge count, payload and pagination metadata verification |
| 18 FCM | device register/unregister API adapter | Firebase setup, token permissions/refresh, platform enum, lifecycle and routing; NOT ENABLED |
| 19 Reporting | report form with example reasons and API call | validate target/reason enum and request field names with backend, link from target screens |
| 20 UX states | loading/empty/retry for new screens | audit all previous screens and Stitch |
| 21 Offline | non-intrusive connection failure banner component | integrate throughout app, cached data persistence, reconnect WebSocket, queued sending (NOT IMPLEMENTED) |

## Important
The user-reported rin1->rin5 real-time issue is NOT fixed by this package. Previous STOMP service is still not integrated into ChatScreen; verify backend endpoint/subscriptions first.
Do not claim offline messaging works. API endpoint/payload assumptions must be tested against the backend contract.
No Flutter SDK is available here; no flutter analyze/test/device execution was performed.

## Run on user's Mac
cd ~/Downloads/mychat-frontend
flutter pub get
dart format lib
flutter analyze
flutter test
flutter run -d R5CXB2MNAWR

Do not push until tests pass and backend contracts are verified.

## Compiler fix (2026-10-08)
Removed invalid STOMP subpath imports and renamed SettingsController.update to updateSetting to avoid AsyncNotifier.update override collision. Flutter analyzer/device build must be rerun on Mac.

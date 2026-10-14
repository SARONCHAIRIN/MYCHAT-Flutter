# MYCHAT Phase 22–25: reviewed patch

## Confirmed changes
- **Phase 22**: Removed duplicate auth imports; logout now sends the stored refresh token in JSON as `refreshToken` (consistent with this app's refresh request), catches Dio errors, clears secure tokens before notification disposal, and resets auth state. Removed raw notification payload logging and rejected non-positive conversation IDs.
- **Phase 23**: Existing app-background polling pause and lazy message list retained. No actual profiling or WebSocket contract verification was possible.
- **Phase 24**: Added accessibility tooltips to chat refresh/send/cancel-reply and home profile/logout controls; added an input label. Broader responsive and screen-reader device checks remain.
- **Phase 25**: Added 3 mocked-Dio logout request tests, alongside existing message tests. Full minimum coverage from the master plan remains outstanding.

## IMPORTANT: logout 400 not conclusively fixed
The Flutter app previously sent POST /api/v1/auth/logout without a body and received HTTP 400. This patch sends `{ "refreshToken": "..." }` when available. This is **a hypothesis based on the refresh endpoint**, not verified against the Spring backend DTO. If the server still returns 400, inspect the actual backend logout endpoint and request schema; do not assume server revocation succeeded. Local token removal is independent of the response.

## Validation required on developer Mac
```
flutter pub get
flutter analyze
flutter test
flutter run -d R5CXB2MNAWR
```
No Flutter SDK or connected Android device is available in this environment; these commands have not been run. Phase 22–25 cannot be marked fully complete until the master plan's remaining security, profiling, accessibility and test requirements pass.

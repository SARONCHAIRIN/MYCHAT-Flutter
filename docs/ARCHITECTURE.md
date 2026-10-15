# MYCHAT Flutter architecture (source audit)

- Entry: `lib/main.dart` initializes Firebase and a Riverpod `ProviderScope`.
- Authentication: `AuthController` (`lib/features/auth/auth.dart`) delegates HTTP to `AuthRepository`, stores tokens in `TokenStore` using `flutter_secure_storage`, and manages notification initialization.
- Networking: shared Dio provider and `ApiPaths` in `lib/core/network/api.dart`. `API_BASE_URL` is a compile-time `--dart-define` setting; default is the current Render backend.
- Screens: `lib/features/ui/screens.dart` contains authentication, home, people, conversation and profile widgets. Chat UI: `lib/features/messages/chat_screen.dart`.
- Messaging: message repository and real-time service are in `lib/features/messages/`. **WebSocket reliability has not been validated on two devices.**
- Notifications: FCM initializer, foreground handler and notification router in `lib/core/notifications/`; device registration in `lib/features/notifications/`.
- State: Riverpod providers; some screens use local StatefulWidget state.
- Routing: `MaterialApp` and Navigator; no assumption of go_router use merely because dependency exists.
- Known gap: backend logout HTTP 400 previously observed; verify server revocation contract.

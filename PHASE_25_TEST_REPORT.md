# MYCHAT Phase 25 — Unit Test Expansion

Based on `MASTER_IMPLEMENTATION_PLAN.md` Phase 25 (auth repository, login, register, token storage, token refresh, refresh concurrency, error mapping, model serialization, conversation repository, message repository, pagination merging, reaction state).

## Implemented in this patch

- Extracted network-only `AuthRepository` for isolated, mocked HTTP testing. `AuthController` now uses it for `me`, `login`, `register`, and `refresh`.
- Coalesces concurrent `AuthRepository.refresh` calls while a refresh is in flight. This applies to calls through the **same AuthRepository instance**; it does not yet coordinate all Dio interceptors or multiple repository instances.
- `TokenStore` now accepts optional injected `FlutterSecureStorage` for tests, retaining the default existing storage for production.
- Moved logout token read inside the `try` block so logout cleanup executes even if reading secure storage throws. This does not resolve backend HTTP 400; the backend contract must be confirmed.
- Added unit tests for auth login/register/me/refresh concurrency/error retry, token save/clear/replacement, conversation/user repositories, reactions API requests, API envelope/error mapping, and message merging.
- Retained previous logout, message repository, and message merging tests.

## Verification required on your Mac

```bash
cd ~/Downloads/mychat-frontend
flutter pub get
dart format lib/core/network/api.dart lib/features/auth/auth.dart lib/features/auth/auth_repository.dart test
flutter analyze
flutter test --coverage
flutter build apk --debug
```

## Scope / limitations

- **Not executed here:** Flutter/Dart SDK is unavailable in this environment. All new tests need local execution and any failures must be resolved before calling the phase verified.
- **Model serialization:** no dedicated typed model/serializer layer exists in the supplied code. The added envelope/payload mapping tests are partial coverage, not a replacement for typed-model serialization tests.
- **Reaction state:** network request tests added; UI optimistic reaction state does not have an extracted testable state reducer, so state behavior remains untested.
- **Token refresh concurrency:** concurrent calls via `AuthRepository.refresh` are coalesced; the Dio auth interceptor still does not implement global automatic 401 refresh/replay. That behavior remains a separate security/architecture task.
- **Logout HTTP 400:** not fixed; server request DTO and authorization must be inspected.
- Phase 25 can be marked complete only after tests pass locally, coverage is reviewed, and remaining model/reaction-state coverage is addressed.

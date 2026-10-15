# API integration map (source-based)

Base URL defaults to `https://mychat-umla.onrender.com` and can be overridden with `--dart-define=API_BASE_URL=https://staging.example`.

| UI / flow | Endpoint | Source |
|---|---|---|
| Login | POST `/api/v1/auth/login` | `lib/features/auth/auth_repository.dart` |
| Register | POST `/api/v1/auth/register` | `lib/features/auth/auth_repository.dart` |
| Current user | GET `/api/v1/auth/me` | `lib/features/auth/auth_repository.dart` |
| Refresh | POST `/api/v1/auth/refresh` | `lib/features/auth/auth_repository.dart` |
| Logout | POST `/api/v1/auth/logout` | `lib/features/auth/logout_service.dart` |
| Users/profile | `/api/v1/users` family | `lib/features/data/repositories.dart` |
| Conversations | `/api/v1/conversations` family | `lib/features/data/repositories.dart` |
| Messages/reactions | conversation/message routes | `lib/features/messages/message_repository.dart` |

This map reflects Flutter call sites, **not** a verified backend OpenAPI contract. Check Swagger/Postman against staging before E2E certification. Never use production user credentials in automated tests.

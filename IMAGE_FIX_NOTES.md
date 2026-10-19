# MYCHAT image fixes (2026-10-19)

- Fixed profile upload caller to match `uploadAvatar(String filePath)` in repository.
- Invalidates shared `authProvider` after avatar upload so screens observing the logged-in user refresh.
- Reuses existing `UserAvatar` / `TelegramAvatar` across screens; relative URLs are resolved against `apiBaseUrl`.
- For IMAGE/FILE messages with missing attachment metadata in history, attempts GET `/api/v1/messages/{id}` once and merges returned metadata.
- Logs network image failures.

**Backend requirement:** If both history and message-detail APIs omit `attachments`/`fileUrl`, Flutter cannot reconstruct the stored image. The backend must return attachment metadata and serve `/uploads/{filename}` with image bytes. If uploads return 404/403, fix server storage and security.

Validation: `flutter analyze` and device testing were not run in this environment (Flutter SDK unavailable).

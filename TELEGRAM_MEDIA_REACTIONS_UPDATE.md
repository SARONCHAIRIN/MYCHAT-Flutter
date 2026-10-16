# MYCHAT Telegram Media + Reactions update (2026-10-15)

- Message bubbles render attachment images returned by the message history API (`attachments`, `attachment`, `files`, `fileUrl`, `attachmentUrl`, `imageUrl`) and the upload response.
- Image load failures render a safe placeholder rather than blanking the message.
- Uploading to an existing message stores the upload response for immediate display and reloads history.
- Fetches reaction lists from `GET /api/v1/messages/{id}/reactions`, groups emoji counts, and renders chips under message text/media.
- Emoji menu reacts and refreshes the chip display without requiring navigation.

## Important backend limitations

The current UI attaches files to an **existing message** using `POST /api/v1/uploads` with `messageId` and `file`. It does **not** create a new media-only message. If the backend requires a different multipart field, or if the upload response uses different fields, adjust `MessageRepository.upload` and `_attachmentsFor` to match the actual OpenAPI `UploadResponse`/`MessageResponse` schemas. The API endpoint's exact attachment response shape was not supplied. Media links must resolve to actual image bytes (not share pages).

Flutter SDK is not available in this environment; run `dart format`, `flutter analyze`, and device testing locally.

# MYCHAT — Flutter REST API integration audit (2026-10-15)

This is a **static** source inspection, not an authenticated production API test. All UI is native Flutter; `design_reference/code.html` is reference material only.

## Corrections made

- Fixed `PATCH /api/v1/users/me/avatar` to send JSON `{avatarUrl}` instead of unsupported multipart upload. Added Profile avatar URL editor. Image upload to storage is **not** provided by this endpoint.
- Fixed message reply field to `replyToId` per Postman.
- Fixed report request to use `reportedUserId`, `conversationId`, `messageId` rather than nonexistent `targetType`/`targetId` request fields.
- Added group-member role change API method.

## API inventory from supplied Postman collection

- `POST /api/v1/auth/register` — Duplicate Register -> 409
- `POST /api/v1/auth/login` — Invalid Login -> 401
- `POST /api/v1/auth/refresh` — Refresh
- `GET /api/v1/auth/me` — Unauthorized Auth Me -> 401
- `POST /api/v1/auth/logout` — Logout
- `GET /api/v1/users` — List Users
- `GET /api/v1/users/search` — Search Users
- `GET /api/v1/users/me` — Get My Profile
- `PATCH /api/v1/users/me` — Update My Profile
- `PATCH /api/v1/users/me/avatar` — Update My Avatar
- `GET /api/v1/users/{{userId}}` — Get User Public Profile
- `GET /api/v1/settings` — Get Settings
- `PATCH /api/v1/settings` — Update Settings
- `POST /api/v1/devices` — Register Device
- `DELETE /api/v1/devices/{{deviceId}}` — Delete Device
- `GET /api/v1/conversations` — List Conversations
- `POST /api/v1/conversations` — Create Group Conversation
- `GET /api/v1/conversations/{{conversationId}}` — Get Conversation
- `PATCH /api/v1/conversations/{{conversationId}}` — Update Group Conversation
- `GET /api/v1/conversations/{{conversationId}}/members` — List Members
- `POST /api/v1/conversations/{{conversationId}}/members` — Add Member
- `PATCH /api/v1/conversations/{{conversationId}}/members/{{memberUserId}}/role` — Change Member Role
- `DELETE /api/v1/conversations/{{conversationId}}/members/{{memberUserId}}` — Remove Member
- `GET /api/v1/conversations/{{conversationId}}/messages` — Get Next Cursor Page
- `POST /api/v1/conversations/{{conversationId}}/messages` — Send Message
- `GET /api/v1/messages/{{messageId}}` — Get Message
- `PATCH /api/v1/messages/{{messageId}}` — Edit Message
- `DELETE /api/v1/messages/{{messageId}}` — Delete Message
- `GET /api/v1/messages/{{messageId}}/reactions` — List Reactions
- `POST /api/v1/messages/{{messageId}}/reactions` — Add Reaction
- `DELETE /api/v1/messages/{{messageId}}/reactions/{{emoji}}` — Remove Reaction
- `POST /api/v1/messages/{{messageId}}/delivered` — Mark Delivered
- `POST /api/v1/messages/{{messageId}}/read` — Mark Read
- `POST /api/v1/conversations/{{conversationId}}/pins/{{messageId}}` — Pin Message
- `GET /api/v1/conversations/{{conversationId}}/pins` — List Pinned Messages
- `DELETE /api/v1/conversations/{{conversationId}}/pins/{{messageId}}` — Unpin Message
- `POST /api/v1/uploads` — Upload Attachment
- `POST /api/v1/users/{{memberUserId}}/block` — Block User
- `GET /api/v1/users/me/blocked` — List Blocked Users
- `DELETE /api/v1/users/{{memberUserId}}/block` — Unblock User
- `GET /api/v1/notifications` — List Notifications
- `POST /api/v1/notifications/{{notificationId}}/read` — Mark Notification Read
- `POST /api/v1/notifications/read-all` — Mark All Notifications Read
- `DELETE /api/v1/notifications/{{notificationId}}` — Delete Notification
- `POST /api/v1/reports` — Report Message

## Important limitations

- The code is not verified with `flutter analyze`, `flutter test`, or live backend calls in this environment (Flutter SDK unavailable).
- Endpoint inventory does not mean every action has an exposed screen or a passing end-to-end test.
- Current message screen has polling; real-time STOMP delivery needs device-to-device verification.
- Avatar editing accepts a public HTTPS URL; gallery upload requires an image storage API not present in the supplied contract.
- Review JWT expiry/refresh behavior and error-state UX before production release.
- Avoid `rsync --delete` and review `git diff` before committing.

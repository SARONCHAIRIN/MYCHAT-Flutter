# MYCHAT — Stitch UI / API Contract Review

## Status

**PARTIAL — FRONTEND AND BACKEND VERIFICATION PENDING.** This archive is a reviewed continuation of the existing Stitch-adapted Flutter source, NOT a verified all-screen redesign. No claim of production readiness.

## Design coverage

The supplied Stitch export contains exactly six reference screens: Splash/session restore, Login, Register, Chats Inbox, Real-time Chat, People/User Search. Other pages have no supplied pixel-accurate design reference. Existing UI for settings, notifications, safety and group flows is preserved; do not describe those pages as matching Stitch.

## Source preservation

The existing Flutter Dio, Riverpod, token storage, WebSocket and Firebase implementations are carried forward from the previously provided compile-fixed archive. This package does not silently replace endpoints or introduce fake data.

## Postman contract inventory

Found 52 requests in 15 sections of the uploaded Postman collection. This inventory documents collection expectations, not live server verification.

| Section | Action | Method | Endpoint |
|---|---|---|---|
| 01 - Authentication | Register | POST | `/api/v1/auth/register` |
| 01 - Authentication | Login | POST | `/api/v1/auth/login` |
| 01 - Authentication | Refresh | POST | `/api/v1/auth/refresh` |
| 01 - Authentication | Get Current Account | GET | `/api/v1/auth/me` |
| 01 - Authentication | Logout | POST | `/api/v1/auth/logout` |
| 02 - Users | List Users | GET | `/api/v1/users?page=0&size=20` |
| 02 - Users | Search Users | GET | `/api/v1/users/search?q={{searchQuery}}&page=0&size=20` |
| 02 - Users | Get My Profile | GET | `/api/v1/users/me` |
| 02 - Users | Update My Profile | PATCH | `/api/v1/users/me` |
| 02 - Users | Update My Avatar | PATCH | `/api/v1/users/me/avatar` |
| 02 - Users | Get User Public Profile | GET | `/api/v1/users/{{userId}}` |
| 03 - User Settings | Get Settings | GET | `/api/v1/settings` |
| 03 - User Settings | Update Settings | PATCH | `/api/v1/settings` |
| 04 - Devices | Register Device | POST | `/api/v1/devices` |
| 04 - Devices | Delete Device | DELETE | `/api/v1/devices/{{deviceId}}` |
| 05 - Conversations | List Conversations | GET | `/api/v1/conversations` |
| 05 - Conversations | Create Direct Conversation | POST | `/api/v1/conversations` |
| 05 - Conversations | Create Group Conversation | POST | `/api/v1/conversations` |
| 05 - Conversations | Get Conversation | GET | `/api/v1/conversations/{{conversationId}}` |
| 05 - Conversations | Update Group Conversation | PATCH | `/api/v1/conversations/{{conversationId}}` |
| 06 - Conversation Members | List Members | GET | `/api/v1/conversations/{{conversationId}}/members` |
| 06 - Conversation Members | Add Member | POST | `/api/v1/conversations/{{conversationId}}/members` |
| 06 - Conversation Members | Change Member Role | PATCH | `/api/v1/conversations/{{conversationId}}/members/{{memberUserId}}/role` |
| 06 - Conversation Members | Remove Member | DELETE | `/api/v1/conversations/{{conversationId}}/members/{{memberUserId}}` |
| 07 - Messages | Get Message History | GET | `/api/v1/conversations/{{conversationId}}/messages?limit=20` |
| 07 - Messages | Get Next Cursor Page | GET | `/api/v1/conversations/{{conversationId}}/messages?before={{nextCursor}}&limit=20` |
| 07 - Messages | Send Message | POST | `/api/v1/conversations/{{conversationId}}/messages` |
| 07 - Messages | Get Message | GET | `/api/v1/messages/{{messageId}}` |
| 07 - Messages | Edit Message | PATCH | `/api/v1/messages/{{messageId}}` |
| 07 - Messages | Delete Message | DELETE | `/api/v1/messages/{{messageId}}` |
| 08 - Reactions | List Reactions | GET | `/api/v1/messages/{{messageId}}/reactions` |
| 08 - Reactions | Add Reaction | POST | `/api/v1/messages/{{messageId}}/reactions` |
| 08 - Reactions | Remove Reaction | DELETE | `/api/v1/messages/{{messageId}}/reactions/{{emoji}}` |
| 09 - Message Receipts | Mark Delivered | POST | `/api/v1/messages/{{messageId}}/delivered` |
| 09 - Message Receipts | Mark Read | POST | `/api/v1/messages/{{messageId}}/read` |
| 10 - Pinned Messages | Pin Message | POST | `/api/v1/conversations/{{conversationId}}/pins/{{messageId}}` |
| 10 - Pinned Messages | List Pinned Messages | GET | `/api/v1/conversations/{{conversationId}}/pins` |
| 10 - Pinned Messages | Unpin Message | DELETE | `/api/v1/conversations/{{conversationId}}/pins/{{messageId}}` |
| 11 - Uploads | Upload Attachment | POST | `/api/v1/uploads` |
| 12 - Blocking | Block User | POST | `/api/v1/users/{{memberUserId}}/block` |
| 12 - Blocking | List Blocked Users | GET | `/api/v1/users/me/blocked` |
| 12 - Blocking | Unblock User | DELETE | `/api/v1/users/{{memberUserId}}/block` |
| 13 - Notifications | List Notifications | GET | `/api/v1/notifications?page=0&size=20` |
| 13 - Notifications | Mark Notification Read | POST | `/api/v1/notifications/{{notificationId}}/read` |
| 13 - Notifications | Mark All Notifications Read | POST | `/api/v1/notifications/read-all` |
| 13 - Notifications | Delete Notification | DELETE | `/api/v1/notifications/{{notificationId}}` |
| 14 - Reports | Report User | POST | `/api/v1/reports` |
| 14 - Reports | Report Conversation | POST | `/api/v1/reports` |
| 14 - Reports | Report Message | POST | `/api/v1/reports` |
| 15 - Phase 24 Negative Tests | Unauthorized Auth Me -> 401 | GET | `/api/v1/auth/me` |
| 15 - Phase 24 Negative Tests | Invalid Login -> 401 | POST | `/api/v1/auth/login` |
| 15 - Phase 24 Negative Tests | Duplicate Register -> 409 | POST | `/api/v1/auth/register` |

## Verification not performed

- Flutter SDK is unavailable in this execution environment: no flutter analyze, flutter test or Android run performed.
- Backend runtime and WebSocket destinations have not been verified against a live Swagger response.
- The collection defaults to localhost:8080 and does not itself prove production API availability.
- Preserve existing API implementations until each endpoint has been compared with backend source and real responses.

## Required next steps

1. Obtain/export every Stitch screen beyond the six currently supplied, if present in the live Stitch project.
2. Run `dart format lib test`, `flutter analyze`, `flutter test` on macOS.
3. Test login, token refresh, chats, realtime and FCM on device `R5CXB2MNAWR`.
4. Complete each screen one phase at a time; record API request/response evidence and changed files.
5. Do not mark a phase COMPLETE until tests and device verification pass.

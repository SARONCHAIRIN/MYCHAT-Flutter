# MYCHAT — MASTER IMPLEMENTATION PLAN

You are a senior Flutter architect, mobile engineer, API integration engineer, and QA engineer.

Your task is to complete the MYCHAT Flutter mobile application from start to production-ready state, integrating the existing Flutter UX/UI with the existing MYCHAT backend.

Do NOT rebuild the backend unless an actual backend defect or missing capability is discovered.

Do NOT replace the existing UI unnecessarily.

The existing Stitch design is the visual source of truth for the Flutter application.

---

## PROJECT SOURCES

### Flutter UX/UI Design

Google Stitch project:

<https://stitch.withgoogle.com/projects/8476140769536198982>

Study the entire Stitch project before implementation.

Preserve:

- layout
- colors
- typography
- spacing
- navigation concepts
- cards
- buttons
- forms
- chat bubbles
- profile layouts
- settings layouts
- dialogs
- bottom sheets
- empty states

Convert the Stitch design into maintainable Flutter widgets rather than hard-coded screenshots.

---

## Backend Repository

<https://github.com/SARONCHAIRIN/MYCHAT>

Study the backend source before implementing API integration.

Do not guess API behavior when it can be determined from the backend.

---

## Production API

Base URL:

<https://mychat-umla.onrender.com>

Swagger:

<https://mychat-umla.onrender.com/swagger-ui/index.html>

API prefix:

`/api/v1`

Use the production API for integration testing unless a local development environment is explicitly required.

---

## PRIMARY OBJECTIVE

Take MYCHAT from:

- Stitch UX/UI
- +
- existing Spring Boot backend

to:

a fully integrated Flutter mobile application.

The final application should support the complete backend functionality currently available.

This is NOT a UI prototype.

This is NOT a fake-data application.

This is NOT a partial API demo.

The final application must communicate with the real MYCHAT backend.

---

## IMPLEMENTATION PRINCIPLES

Use a clean, scalable Flutter architecture.

Separate:

- presentation
- domain/business logic
- data/repositories
- API/network
- models
- local storage
- real-time communication
- services

Do not put API calls directly inside UI widgets.

Do not put authentication logic directly inside screens.

Do not duplicate endpoint URLs throughout the project.

Do not store JWT tokens insecurely.

Do not silently swallow exceptions.

Do not display raw backend exceptions to users.

Do not create endpoints that do not exist.

Do not invent response structures.

Before implementing an endpoint, inspect its actual request and response contract.

---

## RECOMMENDED FLUTTER ARCHITECTURE

Organize the project approximately as:

```text
lib/
app/
core/
config/
constants/
errors/
network/
storage/
theme/
routing/
utils/
widgets/
features/
auth/
users/
conversations/
messages/
notifications/
settings/
profile/
blocking/
reports/
devices/
uploads/
services/
```

Each feature should be separated into appropriate:

```text
data/
domain/
presentation/
```

layers where useful.

Do not over-engineer trivial components.

---

## NETWORKING

Use a robust HTTP client such as Dio.

Create one centralized API client.

Base URL:

<https://mychat-umla.onrender.com>

Configure:

```http
Content-Type: application/json
Accept: application/json
```

For authenticated endpoints:

```http
Authorization: Bearer {accessToken}
```

Implement:

- request timeout
- response timeout
- network exception handling
- HTTP error mapping
- logging in debug builds only

Never log:

- passwords
- access tokens
- refresh tokens
- sensitive personal information

---

## TOKEN STORAGE

Use secure mobile storage for:

- accessToken
- refreshToken

Do not store authentication tokens in plain SharedPreferences.

SharedPreferences may be used for non-sensitive preferences if appropriate.

Create a dedicated token/session storage abstraction.

---

## TOKEN REFRESH

Implement automatic JWT refresh.

Endpoint:

`POST /api/v1/auth/refresh`

Payload:

```json
{
"refreshToken": "…"
}
```

Required behavior:

1. Send authenticated request.
2. Backend returns unauthorized because access token expired.
3. Interceptor detects the authentication failure.
4. Attempt refresh exactly once.
5. Store replacement token(s).
6. Retry original request.
7. If refresh fails, terminate local authenticated session.
8. Navigate user to Login.

IMPORTANT:

Prevent several concurrent failed API requests from triggering several refresh requests simultaneously.

Use a refresh lock/queue/single-flight mechanism.

Never create an infinite retry loop.

---

## ERROR MODEL

Create centralized error handling.

Map common conditions such as:

- 400 → validation/bad request
- 401 → authentication/session problem
- 403 → permission denied
- 404 → resource unavailable
- 409 → conflict
- 5xx → server problem
- timeout → connection timeout
- socket/network failure → offline/network problem

UI must receive meaningful application failures instead of raw Dio exceptions.

Example:

Instead of:

“DioException [bad response]: 401”

display:

“Your session has expired. Please sign in again.”

---

## PHASE 0 — DISCOVERY AND AUDIT

Before modifying code:

1. Inspect the complete Flutter repository.
2. Inspect the Stitch UX/UI.
3. Inspect backend repository.
4. Inspect Swagger/OpenAPI.
5. Inspect provided Postman API collection.
6. Identify existing Flutter architecture.
7. Identify existing dependencies.
8. Identify all existing screens.
9. Identify unfinished screens.
10. Identify mock/static data.
11. Identify fake authentication.
12. Identify hard-coded users/conversations/messages.
13. Identify existing API code.
14. Identify navigation structure.
15. Identify backend/Flutter model mismatches.

Produce:

`PHASE_0_AUDIT.md`

Include:

- existing architecture
- screen inventory
- backend feature inventory
- endpoint inventory
- UI ↔ API mapping
- missing implementation
- technical risks
- proposed implementation sequence

Do not begin large refactoring before understanding the project.

---

## PHASE 1 — PROJECT FOUNDATION

Prepare Flutter project architecture.

Implement/configure:

- environment configuration
- API base URL
- Dio client
- interceptors
- JSON serialization strategy
- error handling
- secure storage
- routing
- state management
- logging
- theme integration

Preserve Stitch visual design.

Recommended state management:

Riverpod

If the project already consistently uses another mature state-management solution, evaluate before replacing it.

Deliverable:

Flutter project runs successfully with architecture ready for real API integration.

---

## PHASE 2 — API CONTRACT LAYER

Create models based on ACTUAL backend responses.

Do not guess JSON.

Create required DTO/domain models for:

- User
- Auth response
- Tokens
- Settings
- Conversation
- Conversation member
- Message
- Reaction
- Notification
- Blocked user
- Device
- Upload/attachment
- Report

Handle nullable backend fields safely.

Implement serialization/deserialization tests.

Create endpoint constants/routes centrally.

---

## PHASE 3 — AUTHENTICATION

Implement:

- Register
- Login
- Session restoration
- Refresh token
- Get current account
- Logout

Endpoints:

`POST /api/v1/auth/register`

Request:

```json
{
"name": "…",
"username": "…",
"email": "…",
"password": "…"
}
```

`POST /api/v1/auth/login`

Request:

```json
{
"username": "…",
"password": "…"
}
```

`POST /api/v1/auth/refresh`

`GET /api/v1/auth/me`

`POST /api/v1/auth/logout`

Connect the actual Stitch Login/Register UI.

Implement:

- form validation
- password visibility
- loading buttons
- API errors
- duplicate account conflict
- invalid credentials
- network failure
- secure token persistence

Expected flow:

```text
App Launch
→ Splash
→ Restore Session
→ Authenticated?
YES → Chats
NO → Login
```

After Register/Login:

- save tokens
- load account
- navigate to authenticated app.

After Logout:

- call backend
- clear tokens
- clear user/session state
- disconnect realtime services
- return to Login.

---

## PHASE 4 — USER ACCOUNT & PROFILE

Integrate:

`GET /api/v1/users/me`

`PATCH /api/v1/users/me`

`PATCH /api/v1/users/me/avatar`

`GET /api/v1/users/{userId}`

Connect:

- Profile
- Edit Profile
- Avatar
- Public Profile

Support:

- name
- username
- email
- phone
- bio
- avatar

Implement loading/error/save states.

After editing profile:

- update cached/current user state without requiring app restart.

---

## PHASE 5 — USERS & SEARCH

Integrate:

`GET /api/v1/users?page=0&size=20`

`GET /api/v1/users/search?q={query}&page=0&size=20`

Implement:

- People screen
- user list
- pagination
- search
- debounce
- loading
- empty state
- retry
- public profile navigation

Do not send API search request for every keystroke without debounce.

Prevent outdated search responses from replacing newer search results.

---

## PHASE 6 — CONVERSATIONS

Integrate:

`GET /api/v1/conversations`

`POST /api/v1/conversations`

`GET /api/v1/conversations/{conversationId}`

`PATCH /api/v1/conversations/{conversationId}`

Implement:

- conversation inbox
- conversation details
- direct conversation creation
- group creation
- group editing

DIRECT creation must follow backend contract.

GROUP creation must follow backend contract.

Replace all fake conversation data with backend data.

Implement:

- loading
- empty
- refresh
- error
- navigation to chat

---

## PHASE 7 — GROUP MEMBERS

Integrate:

`GET /api/v1/conversations/{conversationId}/members`

`POST /api/v1/conversations/{conversationId}/members`

`PATCH /api/v1/conversations/{conversationId}/members/{userId}/role`

`DELETE /api/v1/conversations/{conversationId}/members/{userId}`

Implement:

- member list
- add member
- remove member
- role display
- role update
- permission-aware actions

Require confirmation for destructive member actions.

Do not show administrative actions to users who cannot perform them when backend role information makes that determination possible.

---

## PHASE 8 — MESSAGE HISTORY

Integrate:

`GET /api/v1/conversations/{conversationId}/messages?limit=20`

Cursor pagination:

`GET /api/v1/conversations/{conversationId}/messages?before={nextCursor}&limit=20`

Implement:

- initial message loading
- older-message loading
- cursor pagination
- scroll preservation
- message grouping
- date separators
- sender information
- empty conversation state

Do NOT use page-number pagination if the endpoint uses cursors.

Prevent duplicate messages while merging pages.

---

## PHASE 9 — SEND / EDIT / DELETE MESSAGES

Integrate:

`POST /api/v1/conversations/{conversationId}/messages`

`GET /api/v1/messages/{messageId}`

`PATCH /api/v1/messages/{messageId}`

`DELETE /api/v1/messages/{messageId}`

Implement TEXT messaging first according to actual backend contract.

Support:

- send
- reply
- forward metadata where backend/UI supports it
- edit
- delete

Implement optimistic UI only if rollback behavior is reliable.

Message state should support:

- sending
- sent
- failed

Failed messages should offer Retry.

Prevent accidental duplicate sending.

---

## PHASE 10 — REAL-TIME MESSAGING

Inspect backend WebSocket/STOMP implementation before writing Flutter client code.

Determine actual:

- WebSocket endpoint
- STOMP configuration
- authentication method
- subscription destinations
- send destinations
- event payloads

Do NOT guess destination names.

Implement a dedicated realtime service.

Lifecycle:

```text
authenticated
→ connect
```

```text
logout
→ disconnect
```

```text
app resumes
→ verify/reconnect
```

```text
connection lost
→ controlled reconnect with backoff
```

Incoming messages must merge into existing state without duplicates.

Real-time messages and REST history must use a common message identity strategy.

Do not poll REST continuously when WebSocket is available.

Show subtle reconnect state when appropriate.

---

## PHASE 11 — REACTIONS

Integrate:

`GET /api/v1/messages/{messageId}/reactions`

`POST /api/v1/messages/{messageId}/reactions`

`DELETE /api/v1/messages/{messageId}/reactions/{emoji}`

Implement:

- reaction picker
- reaction chips
- add reaction
- remove reaction
- reaction synchronization

Update chat state without unnecessarily reloading the complete conversation.

---

## PHASE 12 — DELIVERY & READ RECEIPTS

Integrate:

`POST /api/v1/messages/{messageId}/delivered`

`POST /api/v1/messages/{messageId}/read`

Implement message state indicators consistent with the Stitch design.

Avoid repeatedly sending identical receipt calls unnecessarily.

Respect read receipt/privacy settings where applicable.

---

## PHASE 13 — FILE UPLOADS / ATTACHMENTS

Integrate:

`POST /api/v1/uploads`

multipart/form-data:

- messageId
- file

Implement:

- file/image selection
- permission handling where required
- preview
- upload
- upload progress
- failure
- retry
- attachment rendering

Validate backend file constraints before enforcing client restrictions.

Do not assume unsupported file types or size limits.

---

## PHASE 14 — PINNED MESSAGES

Integrate:

`POST /api/v1/conversations/{conversationId}/pins/{messageId}`

`GET /api/v1/conversations/{conversationId}/pins`

`DELETE /api/v1/conversations/{conversationId}/pins/{messageId}`

Implement:

- pin
- unpin
- pinned message indicator
- pinned message list
- jump/open message where feasible with existing API/UI behavior

---

## PHASE 15 — USER SETTINGS

Integrate:

`GET /api/v1/settings`

`PATCH /api/v1/settings`

Support backend fields including:

- theme
- messageNotifications
- groupNotifications
- reactionNotifications
- readReceipts
- lastSeenPrivacy
- profilePhotoPrivacy
- groupAddPrivacy

Connect Stitch Settings UI.

Implement theme synchronization.

- LIGHT
- DARK

Use only enum values accepted by backend.

Do not invent privacy enum values.

---

## PHASE 16 — BLOCKING

Integrate:

`POST /api/v1/users/{userId}/block`

`GET /api/v1/users/me/blocked`

`DELETE /api/v1/users/{userId}/block`

Implement:

- Block User
- Blocked Users
- Unblock

Add confirmation UX.

Refresh relevant state after block/unblock.

---

## PHASE 17 — NOTIFICATIONS

Integrate:

`GET /api/v1/notifications?page=0&size=20`

`POST /api/v1/notifications/{notificationId}/read`

`POST /api/v1/notifications/read-all`

`DELETE /api/v1/notifications/{notificationId}`

Implement:

- notification list
- pagination
- unread/read state
- mark one read
- mark all read
- delete
- empty state
- retry/error state

Update notification badge appropriately.

---

## PHASE 18 — FCM / DEVICE REGISTRATION

Integrate Firebase Cloud Messaging only after verifying backend device platform enums.

Backend:

`POST /api/v1/devices`

`DELETE /api/v1/devices/{deviceId}`

Implement:

- request notification permission when appropriate
- obtain FCM token
- register device
- handle token refresh
- remove device when appropriate

IMPORTANT:

Do not assume ANDROID/IOS values.

Inspect backend enum/DTO first.

Store backend device ID locally if required for cleanup.

Test:

- foreground notification
- background notification
- terminated-app notification
- notification tap routing

Never expose FCM token in UI.

---

## PHASE 19 — REPORTING

Integrate:

`POST /api/v1/reports`

Support backend reporting for:

- user
- conversation
- message

Use actual backend enum values for reasons.

Known API examples include:

- SPAM
- INAPPROPRIATE
- OTHER

Implement:

- report target
- reason selection
- description
- submit
- success
- failure

Do not claim that a report automatically causes punishment.

---

## PHASE 20 — UX STATE COMPLETION

Audit EVERY backend-connected screen.

Every applicable screen must support:

- initial loading
- refreshing
- loaded
- empty
- pagination loading
- validation failure
- API failure
- offline/network failure
- retry
- session expired

Remove development placeholders such as:

- TODO
- fake user
- fake conversation
- Lorem ipsum
- hard-coded message arrays
- temporary buttons
- mock API responses

unless intentionally retained for tests only.

---

## PHASE 21 — OFFLINE & CONNECTIVITY

Implement sensible connectivity behavior.

Do not promise offline messaging unless it is actually implemented.

Handle:

- no internet
- slow internet
- server unavailable
- WebSocket disconnected

Do not immediately destroy useful already-loaded data because a refresh fails.

Display non-intrusive connection/reconnection UI.

---

## PHASE 22 — SECURITY REVIEW

Audit:

- secure token storage
- JWT handling
- refresh flow
- logout
- API logging
- WebSocket authentication
- deep links
- file handling
- input validation

Never commit:

- production secrets
- Firebase service-account credentials
- passwords
- private keys
- JWT tokens

Flutter applications cannot safely hide a secret embedded in the binary.

Do not place backend administrative credentials inside the client.

---

## PHASE 23 — PERFORMANCE

Audit:

- unnecessary widget rebuilds
- large chat lists
- image caching
- message pagination
- search debounce
- network duplication
- WebSocket event duplication
- memory leaks
- controllers
- streams
- subscriptions

Chat history must remain smooth with large conversations.

Use lazy rendering/list virtualization.

Dispose controllers/subscriptions correctly.

---

## PHASE 24 — ACCESSIBILITY & RESPONSIVE UI

Preserve Stitch design while ensuring:

- SafeArea support
- keyboard handling
- small screens
- large screens
- Android
- iOS
- text scaling
- touch target sizes
- contrast
- screen reader labels where appropriate

Test long:

- names
- usernames
- messages
- group names
- notification text

Prevent overflow.

---

## PHASE 25 — UNIT TESTS

Write tests for critical logic.

Minimum coverage:

- auth repository
- login
- register
- token storage
- token refresh
- refresh concurrency
- error mapping
- model serialization
- conversation repository
- message repository
- pagination merging
- reaction state

Use mocked networking for unit tests.

---

## PHASE 26 — WIDGET TESTS

Test critical UI flows:

- Login validation
- Register validation
- Login loading/error
- Conversation list
- People search
- Chat rendering
- Message sending
- Settings
- Profile editing
- Notifications

Test loading/error/empty states.

---

## PHASE 27 — INTEGRATION TESTS

Test against a controlled backend environment.

Critical flow:

```text
Register
→ Login
→ Load profile
→ Search user
→ Create direct conversation
→ Send message
→ Receive message
→ React
→ Mark read
→ Edit message
→ Pin message
→ Open notifications
→ Update profile
→ Update settings
→ Logout
```

Also test:

- invalid login
- duplicate registration
- expired access token
- refresh token
- offline transition
- backend unavailable
- WebSocket reconnect

---

## PHASE 28 — REAL DEVICE TESTING

Test Android first, then iOS if available.

Verify:

- keyboard
- SafeArea
- back navigation
- permissions
- file picker
- image/file upload
- FCM
- background/resume
- WebSocket reconnect
- slow network
- screen rotation if supported
- dark/light mode

Do not consider emulator-only testing sufficient for FCM/mobile lifecycle behavior.

---

## PHASE 29 — CODE QUALITY / CLEANUP

Run:

```sh
flutter analyze
flutter test
```

Format project.

Remove:

- unused imports
- dead code
- temporary debug code
- unnecessary print statements
- obsolete mocks
- duplicate models
- duplicate API clients

Resolve warnings where practical.

Do not suppress meaningful analyzer problems merely to produce a clean output.

---

## PHASE 30 — DOCUMENTATION

Create/update:

`README.md`

Document:

- project setup
- Flutter version
- required dependencies
- architecture
- environment configuration
- backend base URL
- running application
- Android configuration
- iOS configuration
- Firebase setup
- testing
- release build

Also create:

`docs/API_INTEGRATION.md`

```text
Document UI → endpoint mapping.
```

Create:

`docs/ARCHITECTURE.md`

Document:

- state management
- repositories
- networking
- authentication
- token refresh
- WebSocket
- FCM
- routing

---

## PHASE 31 — RELEASE CONFIGURATION

Prepare release configuration without exposing secrets.

Verify:

- Android application ID
- iOS bundle ID
- application name
- launcher icon
- splash
- permissions
- network configuration
- Firebase configuration
- release signing documentation

Do not commit private signing credentials.

---

## PHASE 32 — FINAL END-TO-END QA

Perform a complete feature audit.

### AUTH

- [ ] Register
- [ ] Login
- [ ] Session restore
- [ ] Token refresh
- [ ] Logout

### USERS

- [ ] Current profile
- [ ] Edit profile
- [ ] Avatar
- [ ] User list
- [ ] Search
- [ ] Public profile

### CHAT

- [ ] Conversation list
- [ ] Direct conversation
- [ ] Group conversation
- [ ] Group edit
- [ ] Members
- [ ] Roles

### MESSAGES

- [ ] History
- [ ] Cursor pagination
- [ ] Send
- [ ] Real-time receive
- [ ] Reply
- [ ] Edit
- [ ] Delete
- [ ] Reactions
- [ ] Delivery
- [ ] Read
- [ ] Attachments
- [ ] Pins

### ACCOUNT

- [ ] Settings
- [ ] Theme
- [ ] Privacy
- [ ] Blocking

### NOTIFICATIONS

- [ ] API notifications
- [ ] Mark read
- [ ] Mark all read
- [ ] Delete
- [ ] FCM
- [ ] Device registration

### SAFETY

- [ ] Report user
- [ ] Report conversation
- [ ] Report message

### QUALITY

- [ ] Error states
- [ ] Empty states
- [ ] Loading states
- [ ] Offline handling
- [ ] Dark mode
- [ ] Android
- [ ] iOS
- [ ] Tests
- [ ] flutter analyze
- [ ] Documentation

---

## PHASE 33 — FINAL DELIVERY REPORT

Create:

`FINAL_IMPLEMENTATION_REPORT.md`

Include:

1. Completed phases
2. Implemented screens
3. Implemented endpoints
4. WebSocket functionality
5. FCM functionality
6. Automated tests
7. Manual tests
8. Known limitations
9. Backend issues discovered
10. Remaining TODOs
11. Release readiness

Do not mark something complete merely because UI exists.

A feature is complete only when its real backend integration works and its relevant states are handled.

---

## EXECUTION RULES

Work ONE PHASE AT A TIME.

At the beginning of each phase:

1. inspect relevant existing code
2. inspect relevant backend contract
3. list exact files likely to change
4. state acceptance criteria

Then implement.

After implementation:

1. format
2. analyze
3. run relevant tests
4. fix regressions
5. manually verify where appropriate
6. report changed files
7. report endpoint(s) integrated
8. report tests performed

Only then mark the phase:

COMPLETE

If blocked by a backend issue:

DO NOT fake success.

Mark:

BLOCKED — BACKEND

and document:

- endpoint
- request
- response
- expected behavior
- actual behavior
- evidence
- recommended backend correction

If blocked by Flutter/UI:

Mark:

BLOCKED — FRONTEND

and explain the concrete issue.

---

## GIT / COMMIT STRATEGY

Keep changes phase-oriented.

Suggested commit style:

feat(auth): integrate MYCHAT authentication API

feat(users): connect profile and user search

feat(chat): integrate conversations

feat(messages): implement message history and sending

feat(realtime): integrate websocket messaging

feat(reactions): connect message reactions

feat(settings): integrate user settings

feat(notifications): integrate notifications and FCM

test(auth): add authentication integration tests

docs: document Flutter API architecture

Avoid one enormous commit containing the entire application.

---

## IMPORTANT: DO NOT REWRITE WORKING FEATURES

Before modifying existing Flutter implementation:

inspect it.

If a component already:

- works correctly
- matches Stitch
- uses good architecture
- and connects correctly to backend

keep it.

Refactor only when there is a concrete benefit.

---

## IMPORTANT: API IS SOURCE OF TRUTH

Use:

- backend source
- Swagger/OpenAPI
- Postman collection
- actual API responses

to determine API contracts.

Never guess JSON fields.

Never guess enums.

Never guess WebSocket destinations.

Never guess status codes.

Never create fake endpoints to make the Flutter UI work.

When Stitch contains functionality unsupported by backend:

document:

UI FEATURE NOT CURRENTLY SUPPORTED BY BACKEND

Then either:

disable/hide the interaction appropriately

or

recommend a backend change separately.

Do not silently implement fake behavior.

---

## DEFINITION OF DONE

MYCHAT is complete when:

1. Flutter accurately implements the approved Stitch design.
2. Login/Register use the real backend.
3. JWT access/refresh token lifecycle works.
4. Session restoration works.
5. User/profile features work.
6. Search works.
7. Direct conversations work.
8. Group conversations work.
9. Message history works.
10. Message sending works.
11. Real-time receiving works.
12. Reactions work.
13. Receipts work.
14. Attachments work.
15. Pins work.
16. Settings work.
17. Blocking works.
18. Notifications work.
19. FCM/device integration works where supported.
20. Reporting works.
21. Logout completely clears session.
22. No production screen depends on fake data.
23. Important loading/error/empty states exist.
24. Critical automated tests pass.
25. flutter analyze has no unresolved meaningful errors.
26. Application has been tested on real mobile hardware where required.
27. Documentation is complete.
28. Remaining backend limitations are explicitly documented.

The goal is not merely:

“Flutter app compiles.”

The goal is:

MYCHAT is a functional, maintainable, backend-connected mobile messaging application ready for final release validation.

---

## START NOW

Begin ONLY with:

PHASE 0 — DISCOVERY AND AUDIT.

Do not immediately start rewriting Flutter code.

Inspect:

1. Flutter repository
2. Stitch design
3. backend repository
4. Swagger/OpenAPI
5. Postman collection

Then produce:

`PHASE_0_AUDIT.md`

and propose the exact Phase 1 implementation work.

Wait for approval before proceeding to Phase 1 if operating interactively.

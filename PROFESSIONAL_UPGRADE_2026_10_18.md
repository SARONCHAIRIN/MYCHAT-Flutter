# MYCHAT Professional Stability Update — 18 October 2026

## Implemented
- Unified conversation-avatar URL screening with the shared UserAvatar validation helper.
- Reject Google search redirect URLs (`www.google.com/url`) and share links before attempting image decoding.
- Correctly resolve direct-chat peer names and avatars when member objects have a nested `user` object but avatar/name is on the member itself.
- Added regression tests for Google redirect URL rejection and nested-member peer avatar selection.

## Preserved
Existing Riverpod/Dio APIs, authentication, Drawer, messaging, reactions, and file uploads are unchanged.

## Backend limitation
An avatar URL must serve actual image bytes. HTML sharing links cannot be converted to real images in the Flutter UI. Uploaded message images may still be unavailable across devices if the backend does not persist/serve attachments in message history.

## Validation
Flutter SDK is unavailable in the packaging environment; no compile, device, or live API success is claimed. Run `flutter pub get && flutter analyze && flutter test && flutter run` on your development machine.

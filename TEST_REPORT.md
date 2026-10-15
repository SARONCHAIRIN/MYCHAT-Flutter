# TEST_REPORT

Environment: sandbox without Flutter/Dart SDK; pub.dev, Google storage and the live API host are not
reachable. **No** `flutter pub get`, `dart format`, `flutter analyze`, `flutter test` or APK build was run.
Only a crude bracket-balance check of edited files was done, which is not a compile.

| Item | Status |
|---|---|
| Existing project builds / Android debug build | NOT TESTED |
| flutter analyze / flutter test | NOT TESTED (new tests written, never executed) |
| Login, profile, conversations load | NOT TESTED |
| Avatar fallback | NOT TESTED (unit/widget test written) |
| Direct chat shows correct participant | NOT TESTED (unit test written) |
| Send text, reply, edit, delete | NOT TESTED |
| Image upload / appears in chat / persists | NOT TESTED; persistence is BLOCKED by backend (see limitations) |
| Reactions display / persist | NOT TESTED |
| Pin / unpin | NOT TESTED |
| Realtime updates | NOT TESTED |
| Drawer, Blocked users, Logout | NOT TESTED |
| Settings backend data | NOT TESTED |

Run locally: `flutter pub get && dart format lib test && flutter analyze && flutter test && flutter build apk --debug`.

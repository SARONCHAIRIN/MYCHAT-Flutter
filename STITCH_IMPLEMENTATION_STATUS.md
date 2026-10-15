# MYCHAT Stitch UI implementation — 2026-10-14

## Source of truth
- `design_reference/`: exact six-screen Stitch export (`screen.png`, `code.html`) and `kinetic_slate/DESIGN.md`.
- Original application: `MYCHAT-Stitch-UI-API-contract-reviewed`.

## Updated Flutter files
- `lib/core/theme/stitch_theme.dart`: actual Kinetic Slate color tokens.
- `lib/features/ui/screens.dart`: redesigned login/register, four-tab shell, people directory, chats inbox. Existing Riverpod and repositories retained.
- `lib/features/messages/chat_screen.dart`: conversation header, banner and composer presentation; REST/message actions unchanged.
- `lib/main.dart`: Stitch-style session restore presentation; auth restoration unchanged.

## Important limitations
- This is an implemented UI iteration, NOT a claim of pixel-perfect parity with all six HTML exports.
- Stitch demo's hard-coded sample chats, 401 simulator, sample counts, and fake connection indicators are deliberately not copied into production.
- Existing API repositories, FCM, JWT, and message polling logic were preserved; live endpoint coverage is not verified.
- Flutter SDK is not available in the artifact-building environment; `flutter analyze`, `flutter test`, and device tests must be run on the user's Mac.
- Screen-by-screen fidelity and production real-time transport remain unverified.

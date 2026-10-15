# Phase 31 — release configuration checklist

Current Android `applicationId` and iOS `PRODUCT_BUNDLE_IDENTIFIER` are `com.example.mychat` placeholders. Change them to owned identifiers, update Firebase registrations, and verify provisioning **before release**.

- Android: set application ID, app label, icon, splash, permissions; configure a private release keystore via local/CI secrets. Debug signing has been removed from release build type, but signing is **not yet configured**. Never commit keystore, key.properties or signing passwords.
- iOS: configure bundle ID, signing team/profiles, capabilities, notification entitlement, APNs/Firebase and real-device push behavior on a Mac.
- Ensure Google Services / Firebase configuration matches final IDs, and secrets are excluded from commits.
- Verify HTTPS backend, build numbers, privacy disclosures, store listings, and data deletion/privacy policies.
- Commands: `bash tool/release_preflight.sh`, `flutter build appbundle --release` (only after signing setup), `flutter build ipa --release` (only after iOS signing setup).
- **Release blocked** until identifiers, signing, backend verification and device QA are complete.

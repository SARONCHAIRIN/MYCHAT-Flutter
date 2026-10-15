#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if grep -q 'applicationId = "com.example.mychat"' android/app/build.gradle.kts; then
  echo 'BLOCKED: change Android applicationId from com.example.mychat' >&2; exit 1
fi
if grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.example.mychat' ios/Runner.xcodeproj/project.pbxproj; then
  echo 'BLOCKED: change iOS bundle identifier from com.example.mychat' >&2; exit 1
fi
if grep -q 'signingConfig = signingConfigs.getByName("debug")' android/app/build.gradle.kts; then
  echo 'BLOCKED: debug signing configured for release' >&2; exit 1
fi
echo 'Identifiers checked. Verify CI signing, Firebase registration, permissions and store metadata manually.'

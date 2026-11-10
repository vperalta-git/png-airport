# AeroTrans online Android APK update

Date: 10 November 2026.

## Deliverable

`Android APKs/aerotrans-all-roles-online.apk` - **AeroTrans Connected**, version
1.2.0, build 4, package `com.pngtransfer.png_transfer_client.connected`.
Size: 40,253,883 bytes. ARM32 and ARM64 included in one APK.
SHA-256: `04e0e19380e2dcfafed6938a7a124d42e81e7625e85c7986481bfe5d03d5557e`.

The APK uses the same hosted NestJS backend, persistent test database and test
accounts as the website. It requires internet, with no local computer, emulators
or USB forwarding required. Customer, Control Room, Driver and Supervisor use one
app with separate Arrivals and Departures. The server controls access and workflow.

## Implementation

- Registered the combined Android package in approved test Firebase project
  `aerotrans-png-test-7d7128`. Live `airport-png-c866b` remains unchanged.
- Added native public SDK configuration validation/generation and platform-specific
  Firebase options. Web retains its existing defaults; local emulator mode remains.
- Added a hosted Android manifest and HTTPS-only policy without loopback/cleartext
  exceptions. Explicit initialization occurs only after backend identity checks.
- Extended the existing connected builder with `-Hosted`, version/identity checks,
  native registration checks, public configuration validation and optional install.
- Retained connected package ID and development signing identity for updates. The
  offline APK and original local connected APK files remain unchanged.
- Added reproducible commands and tester instructions; private SDK/account files
  and all APK outputs remain excluded from Git.

Modified: shared Flutter lib/config/app_config.dart and local_firebase.dart;
test/hosted_native_config_test.dart; apps/passenger_web/android/app/build.gradle.kts;
new src/hosted Android manifest/network policy; scripts/build-android-connected.ps1;
scripts/prepare-android-config.mjs; scripts/android-config.test.mjs; package.json;
docs/online-android.md; README.md; docs/hosted-test.md; update.txt; this report.

## Actual verification

- Release APK compiled successfully in 113.6 seconds using existing Flutter/Gradle.
- Export script passed identity/version, native ARM targets, permissions, signature,
  manifest policy, absence of auto Firebase initialization/Google Services resources,
  and packaged Firebase Auth/SharedPreferences/native registration checks.
- New signing certificate matches the previous connected APK.
- Both compiled ARM binaries contain the intended native test app ID/project/API.
  No generated test-account password or private-key marker was found in them.
- Shared Flutter regression: 53 passed, 5 offline-mode-only UI tests skipped with
  normal flags. Flutter analysis: no issues.
- Native and existing public-web config tests: 2 passed. Build PowerShell parser
  check passed. Native config rejects live projects and web IDs in Android settings.
- Real Firebase REST sign-in using the registered Android SDK key and backend
  `/auth/me` authorization passed for all four roles. This checks credentials and
  backend access, not execution of the native Firebase SDK on a device.
- Hosted backend arrival/departure workflow and browser acceptance were already
  verified in AEROTRANS_ARRIVALS_DEPARTURES_REPORT.md; backend workflows are unchanged.
- ADB found no attached device before or after compilation. Installation, actual
  native startup, real-phone login and physical-device acceptance are not claimed.

## Tester access and next action

Send the online APK and privately share the existing website test logins from
ignored `.local-tools/hosted-test/TEST_ACCESS.txt`. No password is embedded in the
APK. Read `docs/online-android.md` for build/install commands.

Connect an unlocked phone with USB debugging authorized to install using
`npm run demo:online:phone`, or install the exported APK directly. Then verify
native startup/login, both transfer directions, account switching and network loss.
No app data needs to be cleared for the same-certificate update.

This is a sideloaded test build signed with the existing development key. Store
release signing and provider integrations are separate work. Test fares are labelled;
payments remain unverified until a real provider confirms them. No production or
payment-provider test, tracking integration or successful notification is invented.

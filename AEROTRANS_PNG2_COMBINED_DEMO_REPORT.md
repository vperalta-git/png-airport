# AeroTrans PNG2 - combined offline demo and Android startup repair

Date: 9 November 2026. Workspace: PNG Airport Transfer/png2.

## Result and scope

The standalone delivery is now one APK, **aerotrans-all-roles-offline.apk**, with
launcher **AeroTrans Demo**. Customer, Control Room, Driver and Manager/Supervisor
share one saved local practice store. The second seeded driver remains available
in the dashboard account chooser. The original online NestJS/Firebase/Flutter
implementation and exported online APKs are retained.

The combined application ID is
`com.pngtransfer.png_transfer_client.offline.allroles`; version code 2, version
name 1.0.1-offline-all-roles. The older separate applications can coexist and are
not automatically uninstalled or cleared. Use the combined APK for current demos;
the original four-APK offline export/ZIP is superseded.

## Confirmed startup/reset bug

The original Android APKs contained SharedPreferencesPlugin but did not contain
Flutter's GeneratedPluginRegistrant. Native storage calls therefore had no
registered Android channel. The bootstrap swallowed the opening error and offered
a reset whose own storage call was unhandled. Launching the native activity with
Status: ok did not establish that Flutter had opened practice data successfully.

On this Windows machine, Flutter's desktop symlink failure interrupted pub get
before generation of Android plugin registration. Subsequent --no-pub builds
compiled and packaged the plugin classes without registering them.

The new Android preparation helper runs flutter pub get --offline successfully
with desktop feature switches disabled only in the current process, restores the
environment afterward, and requires generated native storage registration. It
does not change global Flutter configuration or remove platform folders. Both
existing four-app Android build scripts use this helper too.

The combined build additionally inspects actual APK dex for the registrant and
storage plugin. It verifies package identity, version, ARM32/ARM64, signature,
absence of INTERNET/ACCESS_NETWORK_STATE permissions and FirebaseInitProvider
before export. No backend, Firebase project or internet connection is needed at
runtime, and the normal connected entrypoints retain their behavior.

## UI and recovery changes

- A compact four-role starting screen and the existing dashboard persona switcher
  provide one complete shared booking scenario in a single installation.
- A stateful bootstrap owns the store and displays bounded storage initialization,
  retry and reset errors. It no longer restarts runApp recursively.
- Missing native channels explicitly require a corrected APK; a reset is not
  offered as a cure for missing registration.
- Recoverable data/reset failures remain visible and can be retried. Duplicate
  startup/retry and reset-confirmation actions are guarded.
- Storage clear removes only this offline installation's practice snapshot key.
  Confirmed dashboard reset restores the sample scenario and role chooser.

## Files changed or added for this fix

- packages/png_transfer_flutter_core/lib/offline/offline_demo_app.dart
- packages/png_transfer_flutter_core/lib/offline/offline_demo_persistence.dart
- packages/png_transfer_flutter_core/lib/offline/offline_demo_store.dart
- packages/png_transfer_flutter_core/test/offline_demo_app_test.dart
- apps/passenger_web/lib/main_offline_all_roles.dart
- apps/passenger_web/android/app/build.gradle.kts
- apps/passenger_web/android/app/src/offlineAllRoles/AndroidManifest.xml
- scripts/prepare-android.ps1
- scripts/build-android-all-roles.ps1
- scripts/build-android-offline.ps1
- scripts/build-android-demo.ps1
- scripts/test-all-roles-phone.ps1
- package.json, README.md, docs/offline-demo.md,
  docs/all-roles-offline-demo.md, update.txt and this report.

Flutter generates ignored native registration and plugin metadata as part of
preparation. No handwritten plugin list is maintained. A checkpoint of prior
local work is under ignored .local-tools/checkpoints/before-combined-*.
Flutter also refreshed passenger_web/macos/Flutter/GeneratedPluginRegistrant.swift
to include the existing shared preferences dependency.

## Verification

- Focused combined-role/recovery/store/client tests: 12 passed.
- Shared ordinary-build regression tests: 33 passed, 5 offline-only UI tests
  intentionally skipped without the offline compile flag.
- Focused Flutter analysis: no issues found.
- Combined release compilation and exported APK identity, signature, native
  registration and network-isolation checks passed.
- New recovery tests exercise corrupt storage, failed reset then successful
  recovery, missing native channels, all four entry choices, account switching
  and persisted state.

- The corrected combined APK was installed successfully on the connected
  M2010J19SG (Android 12 / API 31, ARM64). The initial phone approval restriction
  was resolved by the user before retrying. Automatic sandbox approval did not
  reject the action.
- Actual Flutter dashboards for Customer, Control Room, Driver and Supervisor
  were observed on the phone; verification went beyond native activity start.
- UI-confirmed practice reset returned to the chooser with all four buttons.
- A targeted native check selected Control Room, force-stopped the app, reopened
  it, confirmed the same Control Room persona was restored from Android storage,
  and switched back to Customer successfully. Customer was left open.
- Device XML/screenshots are under .local-tools/offline/combined/device. The
  targeted passing snapshots include control-room-confirmed.xml,
  control-room-restored.xml and final-customer-confirmed.xml.
- The broader unattended phone-smoke script did not finish successfully while
  the foreground screen was changing during checks. Its failure result is
  retained; it is not counted as a passed acceptance run. The targeted checks
  above were subsequently completed separately.
- Full physical-device booking/OTP/completion, airplane-mode and provider
  acceptance were not performed. The automated store/client tests cover the
  four-role workflow without an HTTP client. Native packaging has no internet
  permission, but that does not substitute for broader device acceptance.

Final APK: 39,272,487 bytes. Source fingerprint:
2785094566a7fbc9597631e26f519e56a1f1d13775a3737c3bb3862d1158e893.
The sidecar manifest records the APK SHA-256. All four earlier online export
checksums were rechecked and remain unchanged.

## Rebuild and update a connected phone

    npm run demo:all-roles:android
    npm run demo:all-roles:phone -- -DeviceSerial d381fffa0421

The second command builds, installs with adb install -r, and starts the explicit
owner-user activity. It preserves app data for subsequent updates and stops on
dependency, packaging, authorization or installation failures. Choose a different
serial from adb devices when needed. Native activity start alone is reported as
a launcher check, not full workflow acceptance.

See docs/all-roles-offline-demo.md for the tester walkthrough. Practice data
remains local to each phone. Authentication/roles/OTP are simulations; test fares
are unapproved, payments stay pending, and no real GPS, notification, payment
provider or offline-to-online synchronization is claimed. PNG PGK and UTC+10
remain in place. No push, deployment or live data/provider access was performed.

Next: run the full tester walkthrough on a phone, collect flow/usability feedback,
and use the direct USB update command for subsequent fixes. Approved commercial
rates, real authentication/security and multi-phone/provider testing belong to
the retained connected implementation, not this local practice harness.

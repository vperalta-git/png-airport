# AeroTrans PNG2 — separate offline APK report

Date: 9 November 2026. Primary workspace: PNG Airport Transfer/png2.
The user explicitly requested standalone offline demos for remote testers while
retaining the existing online/backend version.

## Delivered modes

- Existing online/emulator mode: unchanged lib/main.dart entrypoints, NestJS,
  Firebase, canonical API client and .demo application IDs. The four original
  exported online APKs retain their SHA-256 checksums.
- New offline mode: separate lib/main_offline.dart entrypoints and .offline
  application IDs. No Firebase initialization, API server or network connection.
- Four offline APKs are in Android APKs/Offline. A ZIP with the APKs, manifest and
  tester instructions is in Android APKs/AeroTrans-Offline-Demo-APKs.zip.
- These are release-mode internal demo APKs signed with the existing development
  signing configuration. They are not store/production releases.
- All four offline packages have distinct Offline launcher labels, min SDK 24,
  and include ARM32/ARM64 support. Android INTERNET and ACCESS_NETWORK_STATE
  permissions and FirebaseInitProvider are absent.
- Both modes can coexist on a phone. Each offline installation keeps independent
  practice data; it does not synchronize with other APKs, phones or the backend.

## Offline functionality

Each APK begins with its named role and contains an accessible role switcher.
This allows a tester to follow the SAME reservation across all four roles inside
one installation, which is necessary without a shared server.

The local practice adapter supports customer account creation/sign-in, PGK test
quotes, bookings, idempotent reservation retry, driver/vehicle availability,
assignment/reassignment, acceptance with inspection, pickup OTP, stage progression,
completion/history, early cancellation, staff management, fleet changes, driver
duty, summaries and audit activity. All mutations persist before being reported
as saved. Failed writes leave the current in-memory state unchanged.

Pickup codes are customer-visible, restricted by assigned driver in the practice
adapter, single-use, expire and lock after five failed attempts. Supervisor reissue
requires a reason. Trip stages cannot skip pickup verification. Resource conflicts,
ownership, active driver/vehicle eligibility and stale revisions are checked.
Reassignment clears prior acceptance and removes the former driver's access.
New practice drivers begin off duty; the seeded ready-to-test drivers are on duty.

Payments stay PENDING throughout. There is no real merchant, GPS, flight,
notification, messaging, security dispatch or evidence upload integration.
Practice authentication and the unrestricted demo persona chooser are simulations,
not validation of Firebase authentication or production security.

Five named personas, three demo vehicles and two explicit practice reservations
are created on first use. One reservation awaits dispatch; one is ready for the
primary driver. Reset affects only this offline installation and recreates fresh
practice dates/codes. Practice data is saved between restarts.

## Preserved architecture and isolation

The existing NestJS/Firebase backend was not replaced or modified for this mode.
The new OfflineDemoClient is an in-process fixture adapter for the existing shared
Flutter screens; it is not an HTTP server or a competing operational backend.
It overrides active get/post/patch methods and never falls back to HTTP.

The offline build flag is explicit and defaults to false. Android packaging reads
that same flag from Flutter's Dart build definitions. The offline manifest is used
only for the separate release-mode build. The build script rejects an APK with
the wrong identity, network permission, Firebase auto-initializer or invalid signature.

No source rebuild was copied over the retained online APK delivery files. A new
online Customer debug build was also compiled and checked: it still has the .demo
identity and normal network access. The normal backend command and normal main
entrypoints remain available for continued connected development.

A pre-change checkpoint of existing online work is in the ignored
.local-tools/checkpoints/before-offline-20261109 folder (patch, untracked files,
manifest). No push, deployment or production data change was performed.

## Modified / added files

Shared Flutter:

- lib/config/demo_mode.dart (new explicit offline build flag).
- lib/offline/offline_demo_store.dart (new practice state, adapters and local flows).
- lib/offline/offline_demo_persistence.dart (new local JSON snapshot persistence).
- lib/offline/offline_demo_app.dart (new offline bootstrap, quick entry, role switcher,
  practice sign-in/registration, local reset and guide).
- lib/offline_demo.dart (separate public offline entrypoint).
- lib/screens/mobile_demo_app.dart, mobile_demo_booking.dart,
  mobile_demo_management.dart (offline labels only when the flag is enabled).
- pubspec.yaml, pubspec.lock, bundled Roboto font and its license.
- test/offline_demo_store_test.dart, offline_demo_client_test.dart,
  offline_demo_app_test.dart.

All four maintained apps (passenger_web, control_room_web, driver_mobile, admin_web):

- lib/main_offline.dart.
- android/app/src/offline/AndroidManifest.xml.
- android/app/build.gradle.kts: conditional offline identity/manifest/packaging;
  ordinary online settings retained.
- pubspec.lock: shared storage plugin resolution.

Tooling / documentation:

- scripts/build-android-offline.ps1 and scripts/browser-offline.mjs.
- package.json: npm run demo:offline:android.
- README.md, docs/android-demo.md, docs/offline-demo.md, update.txt and this report.
- .gitignore keeps the Android APKs delivery folder out of source control.

shared_preferences 2.5.5 supplies local demo persistence. crypto was made an
explicit dependency for local practice credential digests; its implementation is
a mock-login aid, not an operational password service. Roboto is bundled to keep
offline typography self-contained. No hosted service or new backend was added.

## Verification performed

- Shared Flutter regression suite: 33 tests passed; 2 offline-build-only UI tests
  skipped in the ordinary build configuration.
- Offline-flag UI suite: 2 tests passed, covering startup, all four role defaults,
  accessible switching, guide, reset and a 390px phone layout.
- Offline store/client tests are included above: full workflow, persistent state,
  required acceptance, attempted state skipping, driver-only access, OTP lockout,
  reissue/replay, pending payment, dispatch conflicts, reassignment, local account
  lifecycle, management, reset, idempotent retry and failed-save rollback.
- HTTP creation is forbidden in the typed offline-client integration test; all
  the tested quote/booking/read operations complete without an HTTP client.
- Focused Flutter analysis of new/changed implementation and tests: no issues.
- Existing four-app online startup/UI tests: 8 passed.
- Four offline Flutter web builds passed.
- Compiled browser acceptance: all four offline role homes start with API/Firebase
  access blocked; one shared local reservation completes customer booking,
  control dispatch, driver acceptance, OTP pickup, completion and supervisor audit.
  Reload persistence and local reset passed. No JavaScript runtime errors remained.
- The optional browser harness serves its own static assets and fulfils the web
  engine's fallback-font request from the bundled local font; it does not fetch
  fonts or data from the internet. Backend/Firebase URLs are blocked.
- Four offline Android release builds passed signature, package identity and
  manifest-isolation checks before export.
- Original online Customer debug build passed and retained .demo/network behavior.
- The four previously exported online APK checksums remain unchanged.
- Android device runtime / airplane-mode testing was NOT performed: ADB reported
  no connected phone. Builds and browser checks do not establish physical-device
  acceptance.

Windows Flutter pub get resolves the new dependencies, but desktop symlink
generation remains unavailable on this machine. Android/web builds use the
resolved package configuration with --no-pub, as in the retained foundation.

## Tester instructions and remaining limits

Send the offline files, not the older *-demo.apk files. Follow
docs/offline-demo.md or the included TESTER-README.txt.

Testers can install the APK directly, start the demo and use airplane mode.
No laptop, USB, Firebase project, backend URL or account provisioning is needed.

Each APK has its own practice records. To exercise the complete four-role flow,
switch roles within one APK; do not expect records to move between the four APKs
or between phones. Use made-up details only. Clearing storage/uninstalling removes
that installation's data. Local preferences are suitable for demonstration data,
not the operational record of the retained connected system.

Test fares remain the prior explicit demo values: PGK 100.00 sedan, PGK 150.00 SUV.
These are not approved tariffs and zero test tax is not a tax policy. Lae/Nadzab
times display in PNG UTC+10. Initial examples exercise inbound airport-to-city
transfers; existing outbound stage terminology still needs business review.

Next steps: perform physical-phone testing, collect usability/flow feedback, and
apply accepted improvements to the shared screens while preserving both modes.
Real multi-phone integration/security/provider testing belongs in a separately
authorized connected test environment.

## Phone installation follow-up - 9 November 2026

All four offline APKs were subsequently installed successfully on the connected
M2010J19SG phone (Android 12 / API 31, ARM64). Each APK checksum matched the export
manifest. All four explicit native launcher checks returned Status: ok. Customer
was brought to the foreground afterward. The phone's initial USB installation
restriction was resolved by the user before the successful retry.

This supersedes the earlier statement that no phone had been connected. Full
physical-device workflow and airplane-mode acceptance remain unperformed; these
results establish installation and native activity launch only.

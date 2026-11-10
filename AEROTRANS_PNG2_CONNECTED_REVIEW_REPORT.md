# AeroTrans PNG2 - unified connected review app

Implementation: 9 November 2026. Source handoff: 10 November 2026.
Primary workspace: PNG Airport Transfer/png2.

## Completed

One Flutter entrypoint, apps/passenger_web/lib/main_connected.dart, supports all
four workspaces against the existing NestJS/Firebase backend. Customer registration
and login use the existing Auth/API flow. Role cards are sign-in entry choices;
the active backend profile determines permissions and the workspace rendered.
No offline adapter, demo persona login, embedded passwords or replacement server
is used in this build.

The session controller verifies UID, active status, supported role and canonical
organization/branch/airport scope. It rejects stale profile responses after an
account change, guards duplicate actions, supports profile retry after network
failure and destroys the previous account's navigation routes. Account switching
signs out before another login. An unavailable logout endpoint is distinguished
from confirmed server revocation; local sign-out remains possible.

The shared UI now uses bundled typography, navy/gold controls, responsive content
widths, dashboard summaries, stronger reservation/status hierarchy, password
visibility, better empty/error/loading states and account navigation. Existing
booking, dispatch, pickup OTP, trip, management and payment-state flows remain
API-backed. PGK integer minor units and PNG UTC+10 displays remain in place.

## Android export and isolation

Artifact: Android APKs/aerotrans-all-roles-connected.apk.
Launcher: AeroTrans Connected.
Package: com.pngtransfer.png_transfer_client.connected.
Version: 1.1.0, code 3; Android API 24+, ARM32/ARM64.
Size: 40,286,787 bytes.
SHA-256: bae3e3f790de9ca07ad3722879b8cc3f8deca6ca11b2961ba2ed094c497a26ca.
Source fingerprint: 9210ba97699095815ed5aedf855da878079fa11ae839a1887d9f87645d66e392.

The compiled/exported APK passed signature, identity, native plugin registration,
Firebase Auth/storage class and restricted network-policy checks. Firebase options
are explicit and emulator-only; FirebaseInitProvider is absent. The Google Services
plugin is not applied to this mode, preventing stale generated configuration from
another build from entering the APK. The build rejects cached Firebase resource
values and resolves optimized Android XML resource names before policy inspection.
HTTP is allowed only for the known loopback development hosts. AppConfig continues
to reject external API origins; there is no silent production fallback.

The separate offline APK and its saved data/package were retained. Exported APKs,
credentials and generated output are ignored by Git and are not source artifacts.

## Verification actually performed

- Shared Flutter suite: 45 passed, 5 offline-flag-only UI tests skipped normally.
- Separate offline UI preservation suite: 5 passed after the shared UI changes.
- Connected session/widget tests: 12 passed, included in the 45 above. Coverage
  includes role hints versus real authorization, UID/scope/active validation,
  denied access, network retry, stale sessions, duplicate actions, navigation
  cleanup, login field preservation and startup recovery.
- Focused Flutter analysis: no issues in the changed/new implementation and tests.
- Backend verification: 8 suites / 22 tests passed. The comprehensive real-emulator
  four-role integration passed authentication, authorization/ownership, authoritative
  quotes, idempotency, assignment/reassignment/conflicts, acceptance, OTP lock/
  reissue/replay, trip completion/cancellation, payment separation and management.
  Other suites cover guards/contracts/isolation and mocked HTTP foundation cases.
- Android connected release compilation and export checks passed.
- Unified connected Flutter website compilation passed (49.1 seconds):
  flutter build web --no-pub --target lib/main_connected.dart
  --dart-define=AEROTRANS_CONNECTED_REVIEW=true --no-web-resources-cdn.
  This is compilation, not browser/backend acceptance or deployment.
- Native connected-app login/workflow acceptance has not yet been performed.
  On 10 November the phone was no longer detected and local services were stopped.
  The APK is built; installation and actual phone acceptance remain pending a
  connected/unlocked device. The earlier offline APK's phone checks do not count
  as connected-app acceptance.

The tests used isolated local fixtures and cleaned their own records. No production
access, deployment, public tunnel, live provider call or actual payment occurred.

## Modified/added source

- packages/png_transfer_flutter_core/lib/connected/connected_session.dart
- packages/png_transfer_flutter_core/lib/connected/connected_review_app.dart
- packages/png_transfer_flutter_core/lib/theme/aviation_theme.dart
- packages/png_transfer_flutter_core/lib/screens/mobile_demo_app.dart
- packages/png_transfer_flutter_core/lib/screens/mobile_demo_booking.dart
- packages/png_transfer_flutter_core/lib/screens/mobile_demo_management.dart
- packages/png_transfer_flutter_core/test/connected_session_test.dart
- packages/png_transfer_flutter_core/test/connected_review_app_test.dart
- packages/png_transfer_flutter_core/test/support/connected_review_fakes.dart
- apps/passenger_web/lib/main_connected.dart
- apps/passenger_web/android/app/build.gradle.kts
- apps/passenger_web/android/app/src/connected/AndroidManifest.xml
- apps/passenger_web/android/app/src/connected/res/xml/connected_network_security_config.xml
- scripts/build-android-connected.ps1, scripts/test-connected-phone.ps1
- package.json, README.md, docs/connected-review.md, update.txt and this report.

## Run and next steps

Use docs/connected-review.md. Start the existing local emulators/backend only if
they are stopped. Run npm run demo:setup for owned local accounts/fleet when needed;
generated passwords stay in ignored .local-tools/demo/accounts.json.

    npm run demo:connected:phone -- -DeviceSerial <serial>

This rebuilds, checks readiness, forwards local ports, installs with -r and launches
the one connected application. It preserves app data. The native smoke helper is
available for supervised testing; it has not been counted as a passed device run.

Next, install on a connected phone, verify all four real logins and run the booking
walkthrough. A remotely shared APK requires a hosted nonproduction backend and
matching Firebase test configuration; those services/credentials are not supplied.
Commercial tariffs/tax and payment/notification/tracking integrations remain
business/provider work, separate from this local review runtime.

## Source publication

The user authorized a source push on 10 November 2026 to
https://github.com/vperalta-git/png-airport. This does not authorize deployment or
uploading local credentials, emulator snapshots or APKs. The empty destination is
receiving a clean current-source snapshot, preserving the original local history
without publishing legacy hardcoded account/contact records. See
SOURCE_PUBLICATION.md. Final commit/remote verification is reported separately;
do not infer a hosted site from the GitHub repository alone.

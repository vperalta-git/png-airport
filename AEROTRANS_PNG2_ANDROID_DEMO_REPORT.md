# AeroTrans PNG2 — four-role Android demo implementation

Date: 6 November 2026. Target: all four roles on real Android phones.
Workspace: C:\Users\Vionne\Documents\PNG Airport Transfer\png2.
Architecture remains NestJS + Firebase + Flutter. The older React/SQLite project
was not introduced. No push, deployment, production account/data access or live
provider transaction was performed.

## Delivery status

The four primary applications now launch shared, authenticated mobile workflows.
Debug ARM32/ARM64 APKs are generated in ignored `.local-tools/demo/apks/`, with
separate .demo package IDs and explicit demo labels. Use
[docs/android-demo.md](docs/android-demo.md) for startup, USB installation, local
credentials, a walkthrough and troubleshooting.

APK SHA-256 checksums and the source fingerprint were verified against the
current source. All four packaged manifests have the expected demo identity and
exclude FirebaseInitProvider. Browser screenshots were inspected for mobile
layout and navy/gold styling. Local backend/emulator services were left running.

This is a computer-hosted, USB-connected demonstration. ADB reported no connected
phone during implementation. Android installation, native Firebase startup,
keyboard/navigation behavior and a physical-device walkthrough remain unverified.
The APK builds are not evidence of device testing or a standalone cloud release.

## Existing work and checkpoint

Verified repository: rmartinezgh/airport-png2, branch main, starting commit
d6511232f4733a5ae2c566f489e0c7624301aeb4. Batch A already had local uncommitted
work. It was preserved before these changes in
`.local-tools/checkpoints/before-android-demo/`: tracked patch, untracked source
copies and manifest. The earlier checkpoint/batch-a-20261106 reference remains.
All current work remains local and uncommitted.

## Completed functionality

### Customer

- Firebase email/password sign-in through the SDK; backend registration grants
  only PASSENGER in the configured isolated Lae scope.
- Backend-owned profile and custom claims, without frontend role/header fallbacks.
- Airport transfer form, PNG pickup time, passenger manifest, capacity/luggage
  validation and server-generated, expiring quotations.
- Booking creation consumes a customer-owned quote atomically and preserves the
  same intent on retries. A quote-derived client key works on both Dart VM and web.
- Reservation list, active/history filters, booking detail, real driver/vehicle
  information, trip activity, owning-customer pickup code and early cancellation.

### Control Room

- Scoped operational summaries, reservation list and trip details.
- Actual driver duty, completed-trip totals, vehicle status and availability.
- Assign/reassign eligible driver and matching vehicle before departure.
- Transactional resource locks prevent simultaneous dispatch of the same resource.
- Reassignment clears previous acceptance; cancellation releases active locks.
- Stale revision/conflict/network errors surface to the user for refresh.

### Driver

- Only assigned bookings are visible; a reassigned former driver loses access.
- On-duty setting and accurate backend-derived completed trip count/history.
- Acceptance requires all four pre-trip check confirmations.
- Departure, arrival at pickup, OTP verification, transfer, destination arrival
  and completion use server-enforced transitions and expected revisions.
- Only the assigned driver can verify pickup. Codes expire, are single-use,
  accumulate failures transactionally and lock after five incorrect attempts.
- Trip completion never marks payment paid.

### Manager / Supervisor

- Scoped activity summaries, reservations, drivers, fleet and audit records.
- Staff creation for DISPATCHER, DRIVER and SUPERVISOR; edit name/contact and
  active/suspended state. Staff scope is derived from the authorized manager.
- Suspension blocks existing tokens through the backend profile check and
  disables/revokes the Firebase account. Self-suspension is rejected.
- Fleet creation with unique plate indexing; edit name/status and driver duty.
- Active resources cannot be edited/off-duty while locked by a trip.
- Supervisor OTP reissue requires a reason and is audited; completed trips can
  be closed without releasing locks owned by a newer booking.
- MANAGER is not a separate wire role; Supervisor is the required managerial role.

### Shared reliability and isolation

- Upgraded existing Nest modules rather than adding another backend.
- Global token and role guards require explicit role, organization, branch and
  airport claims and an active matching server profile.
- Existing versioned envelopes, string identifiers, canonical DTOs, PGK integer
  minor units and separate payment states are retained.
- Booking events/audit mutations are persisted; event ordering uses revision/step.
- No demo booking fallback, automatic hardcoded driver assignment, fake paid
  settlement, fake offline-sync acknowledgment, notification or tracking result.
- Legacy/unconverted controllers stay unavailable behind the foundation guard.
  Direct Firebase client operational access remains denied; the API is authoritative.
- Shared mobile screens reuse AviationTheme and the shared API/contract package.
  Existing legacy screens, BLoCs, domain models and duplicate folders remain.
- Forms block duplicate taps, report errors, show loading/empty/stale states and
  retain an uncertain booking intent for a safe retry.
- Lists/details poll authoritative state every five seconds. Polling pauses when
  a screen is covered by a dialog or another route.
- Firebase SDK automatic Android localhost remapping is disabled, preserving the
  explicit 127.0.0.1 USB endpoint. Debug manifests defer Firebase initialization
  until local readiness checks and permit debug HTTP; main manifests disallow it.
- Android Gradle/Kotlin versions were aligned with installed Flutter 3.35.4:
  AGP 8.9.1, Gradle 8.12, Kotlin 2.1.0. Actual APK metadata reports min API 24,
  target API 36, arm64-v8a + armeabi-v7a.
- APK helper fingerprints maintained Dart source and records SHA-256 checksums,
  avoiding stale Windows Gradle output after shared source changes.
- The demo backend compiles once and runs without watch mode. Snapshot or handoff
  writes cannot interrupt active API requests by restarting a development watcher.
- Explicit demo setup creates only owned, labelled emulator accounts/fleet.
  Random credentials are saved locally in an ignored file and are not in this report.
- Local snapshot export/import was added. Auth accounts, scoped profiles and fleet
  were restored and authenticated after a real emulator restart, without reseeding.

## PNG configuration and money

Pilot remains Lae / Nadzab, currency PGK, Pacific/Port_Moresby (UTC+10).
PNG eight-digit phone input is normalized to +675; explicit international numbers
are validated and preserved. No Philippine settings were introduced.

No operator-approved pricing is available. Normal backend startup leaves rates
unconfigured. `npm run demo:backend` explicitly enables server test fixtures:
sedan 10000 minor units / PGK 100.00; SUV 15000 / PGK 150.00. Every mobile app
shows the isolated-demo/test-fare notice. Test taxMinor=0 is not an approved tax
policy. Cash selection is a preference only. Payments remain PENDING because
no payment verification/collection provider is configured.

## Modified files in this implementation

The earlier Batch A changes remain in the working tree. This demo adds/updates:

- `backend/src/app.module.ts`, `main.ts`, `health.controller.ts`,
  `contracts/contracts.controller.ts`.
- `backend/src/common/workflow.ts`; `common/guards/auth.guard.ts`,
  `roles.guard.ts`, `foundation.guard.ts`.
- `backend/src/config/demo.ts`, `config/config.controller.ts`.
- Existing `backend/src/modules/auth/`: service, controller, module.
- Existing `backend/src/modules/bookings/`: service, controller, service spec.
- Existing `backend/src/modules/quotations/`: service, controller, service spec.
- Existing `backend/src/modules/resources/`: service and controller.
- Existing `backend/src/modules/dispatch/`, `trips/`, `reports/`: services
  and controllers; existing module registration remains.
- `backend/src/modules/payments/payments.service.ts` and
  `modules/offline-sync/offline-sync.service.ts`.
- `backend/test/demo.integration.ts`, `test/jest-demo.json`,
  `test/foundation.e2e-spec.ts`.
- Shared Flutter `lib/services/png_api_client.dart`,
  `lib/config/local_firebase.dart`, `lib/png_transfer_flutter_core.dart`.
- New shared `lib/screens/mobile_demo_app.dart`,
  `mobile_demo_booking.dart`, `mobile_demo_management.dart`,
  `test/mobile_demo_test.dart`.
- In passenger_web, control_room_web, driver_mobile and admin_web:
  `lib/main.dart`, `test/widget_test.dart`, Android settings,
  app Gradle files, wrapper properties and main/debug manifests.
- Debug-only demo `google-services.json` variants for passenger_web,
  control_room_web and driver_mobile contain placeholder emulator identifiers.
- Root `package.json`; `scripts/local.mjs`, `demo-setup.mjs`,
  `demo-phone.mjs`, `demo-test.mjs`, `build-android-demo.ps1`,
  `browser-demo.mjs`.
- README, application/contract/local development guidance, this report,
  `docs/android-demo.md` and forwardable `update.txt`.

## Verification actually performed

| Check | Result |
| --- | --- |
| Backend compilation: npm --prefix backend run build | Passed |
| Backend unit tests: npm --prefix backend test | 6 suites, 20 tests passed |
| Shared TypeScript analysis: npm run typecheck | Passed |
| Shared TypeScript fixtures/policy tests | 5 passed |
| Local environment isolation tests | 2 passed; conflicting cloud config rejected |
| Auth/Firestore/RTDB/Storage smoke test | Passed; own fixtures cleaned |
| Nest HTTP envelope/guard foundation test | 1 passed |
| Four-role real HTTP + emulator integration | 1 extensive scenario passed using separate accounts and random isolated organization; own records cleaned |
| Shared Flutter tests | 26 passed, including form validation, duplicate submission blocking, uncertain booking retry and payment/history display |
| Four app startup/login/error tests | 8 passed, 2 per app |
| Focused Flutter analysis on changed shared code/tests | No issues |
| Four Flutter web builds | Passed for browser acceptance |
| Four debug Android APK builds | Passed; metadata/ARM ABIs/demo package IDs inspected |
| Local emulator snapshot export and restart/import | Passed; saved identities/profiles/fleet recovered without reseeding |
| Compiled demo launcher stability | Passed; the final browser workflow uses the compiled server, which retained its process while handoff files changed |
| Compiled Flutter browser workflow | Passed: real four-role sign-in, customer server quote/booking, control assignment, driver checks/departure/OTP/transfer/completion, supervisor audit; payment pending; no non-local data/API requests or JS runtime errors |
| Physical phone / Android emulator runtime | Not performed; no connected Android device |
| Production, merchant, GPS, messaging, real flight or other provider integration | Not performed |

The API integration covers public registration and role injection rejection,
foreign/customer/driver scope, manager permissions, server quotes, retry after
quote expiry, assignment/reassignment and lost old-driver access, required
acceptance, forbidden generic verification, OTP attempts/lock/reissue/replay,
completion/history, separate pending payment, racing resource assignment,
cancellation, account suspension, self-suspension and scoped audit activity.

Some Node test workers initially hit sandbox spawn EPERM; their reruns outside
that restricted process sandbox passed. Windows desktop symlink generation is
still unavailable; existing resolved dependencies permitted --no-pub Android/web
builds and tests. First native build exposed incompatible original Gradle/Kotlin
versions; the aligned toolchain builds successfully. One emulator restart required
stopping the positively identified leftover demo Firestore process after shutdown.
No unrelated process was terminated.

## Remaining work and decisions

1. Connect a real phone, authorize USB debugging, run the phone install helper and
   perform the entire four-role walkthrough. Check native Firebase startup,
   app switching, keyboard, back navigation, reconnection and lifecycle behavior.
2. Decide whether the public demo must work without the laptop/USB. That needs
   separately authorized nonproduction hosting/Firebase configuration and access;
   it has not been deployed or enabled here.
3. Obtain operator-approved Lae routes, tariffs, capacity/compliance policies,
   cancellation rules and tax treatment before commercial use.
4. Select and authorize actual payment, GPS/map, flight, SMS/WhatsApp/notification
   providers where needed. None are represented as integrated.
5. Add password recovery/verification and a staff invitation/password-change flow,
   abuse/rate limiting, production rule/configuration review, operational monitoring,
   backup/restore policy, pagination and credential/release signing management.
6. Persist an interrupted client booking intent across process death; current safe
   automatic retry protection covers the open form/session. Verify reservations
   before starting another form after an app restart.
7. Current resource locks are conservative: one unfinished assignment per driver
   and vehicle regardless of scheduled time. Scheduling/overlap policy needs an
   operator decision. Mid-trip reassignment/abort handling is not activated.
8. Expand corporate/security/operator workflows, compliance, e-POD and offline
   sync through the existing models only after the core demo is accepted.
9. Duplicate Flutter folders remain intentionally undeleted. Only the four primary
   entrypoints launch the new demo; native platforms other than Android are not
   verified.
10. The demonstrated workflow is inbound airport-to-Lae. Outbound transfers are
    accepted by the shared contract but retain the legacy AT_AIRPORT pickup-state
    name; confirm/refine directional stage semantics before outbound operations.

## Recommended next phase

First complete physical-phone acceptance and fix any native/device issues.
Then prepare a controlled nonproduction hosted pilot with approved pricing and
operator configuration, account lifecycle/security hardening and a signed internal
Android distribution. Integrate providers independently with verifiable outcomes.
Do not treat this isolated demonstration as a production release.

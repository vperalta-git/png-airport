# AeroTrans PNG2 - Batch A implementation report

Date: 6 November 2026 (Asia/Singapore).
Workspace: C:\Users\Vionne\Documents\PNG Airport Transfer\png2.
Repository: https://github.com/rmartinezgh/airport-png2.

## Result

Batch A is implemented as a tested **local development foundation** in the existing
NestJS/Firebase/Flutter architecture. There is one demo project, one backend and
one versioned booking/quotation contract. No React/SQLite backend was introduced.

The four primary Flutter entrypoints now initialize the emulators and display
local setup/readiness using the existing aviation theme. Their previous screens,
BLoCs, widgets, signboard/verification/incident/financial concepts and expansion
apps are preserved in source. **Operational app activation remains Batch B work.**

The old flows contained fake sessions, unauthenticated mutations, client writes,
hardcoded fares/payment success and simulated verification. They are quarantined:
the global foundation guard permits health/contract metadata and returns structured
503 WORKFLOW_NOT_READY for other controller workflows. No environment flag
silently enables them. Existing legacy app builders are retained as legacyMain,
not launched. Do not remove the boundary merely to restore prototype behavior.

No push, deployment, production data access/migration, real provider transaction
or production credential configuration occurred. Dependency downloads, official
static SDK/font assets, emulator data and localhost APIs were used.

The local backend and emulator test processes were stopped after verification.
Ports 8080, 9099, 8085, 9000 and 9199 were confirmed closed.

## Checkpoint and preservation

- Initial branch main, clean working tree, HEAD
  d6511232f4733a5ae2c566f489e0c7624301aeb4.
- Created checkpoint/batch-a-20261106 at that exact commit before editing.
- Current work remains local and uncommitted on main. No application folder was
  deleted. The older reference project's source was not modified by this batch.
- Only the unsafe ambient typings.d.ts workaround was removed. Original state is
  recoverable from the checkpoint; no credentials were added to source.

## Implemented changes

### Local Firebase isolation

- Root package scripts and pinned Firebase CLI with a lockfile; explicit
  demo-aerotrans-png2 project and loopback Auth/Firestore/RTDB/Storage services.
- Both active Firebase config files are local-only. Old cloud hosting rewrites are
  retained as an inactive infrastructure example. CLI aliases no longer default
  to a real cloud project.
- Local runner rejects inherited credentials, conflicting project IDs and
  unexpected endpoint/database/bucket overrides; uses an isolated CLI config path.
- Backend validates all four emulator variables and reachability before SDK use,
  binds HTTP to loopback, uses a demo bucket/namespace and refuses production mode.
  No malformed-credential fallback to a live default project remains.
- Shared Flutter bootstrap validates the local backend identity, probes services
  with timeouts, connects all four Firebase SDKs and blocks launch on failure.
  RTDB readiness uses the exact demo namespace. Startup has an overall timeout.
- All 11 Flutter entrypoints use that bootstrap. Existing Firebase option and
  native JSON files now contain demo-only identifiers; Android HTTP allowance
  is debug-only. Physical-device/native behavior is not claimed as verified.
- API clients reject cloud origins and redirects. CORS accepts explicit local
  Flutter origins only. Real .env/credentials, caches and emulator artifacts are
  excluded from Git.
- Direct Firestore/RTDB/Storage client access is denied by default pending Batch B
  ownership rules. A real emulator check confirmed a signed-in client cannot
  write itself SUPER_ADMIN. Admin test writes remain allowed by the Admin SDK.
- Operational seeds and production startup are disabled.

### Backend/tooling

- Installed the existing NestJS dependencies, added a reproducible backend
  package-lock.json and verified a clean offline npm ci from the local cache.
- Real installed Nest/Firebase/Jest types now drive builds; broad ambient module
  declarations were removed. All 14 existing modules remain registered.
- Shared types compile before backend build/tests/start. Restored working e2e
  configuration and actual HTTP tests. lint is explicitly TypeScript static
  analysis, not an assertion that an ESLint setup exists.
- Added working formatter tools and checked modified TS/JS/JSON files.
- Shared root TypeScript analysis covers backend and package source using actual
  Jest/Node declarations, without fake library types.
- Canonical guard removes automatic developer/worker identities and profile-role
  trust. It requires verified/revocation-checked Firebase tokens with canonical,
  server-managed role/scope claims. RolesGuard has no SYSTEM/admin wildcard.
  These helpers must be connected to activated business services in Batch B.

### Canonical contract

- Version 1 public TS exports, strict request/response parsers, Nest validation
  pipes, typed TS/Dart clients and representative shared JSON fixtures.
- Opaque string Firebase IDs; uppercase canonical roles/statuses; explicit
  organization/branch/airport/customer ownership; PGK safe-integer minor units;
  balanced totals, rate version, quote identity/expiry and offset-aware times.
- Defined independent payment states, booking revision, assignment fields and
  permitted role/state transitions. Generic state changes cannot verify pickup.
- PAID structurally requires reference/time evidence; actual trusted verification
  remains provider/service work and cannot be established by a parsed payload.
- Consistent schemaVersion/success/data/error/meta envelopes and safe errors.
- Fixtures are labelled TEST-ONLY; taxMinor=0 is not an approved tax policy.
  No operator tariff was invented/configured and pricingConfigured remains false.
- Original numeric/snake_case TS declarations are explicit legacy models, not
  public v1 wire contracts. Old Dart presentation/internal Nest entities remain
  quarantined until service/UI migration in Batch B.
- Removed the shared legacy repository's local fare heuristic so a failed server
  quote cannot generate an invented authoritative price.

### Flutter structure

Maintain passenger_web, control_room_web, driver_mobile and admin_web.
Share configuration/contracts/theme/services through png_transfer_flutter_core.
Expansion corporate/security/operator apps remain preserved.

Before modification, full app/native comparisons found:

| Pair | Files at checkpoint | Differences |
| --- | --- | --- |
| client_flutter / passenger_web | 160 / 160 | login/profile Dart screens |
| control_room_flutter / control_room_web | 155 / 155 | trailing blank line in service |
| driver_flutter / driver_mobile | 153 / 152 | driver devtools_options.yaml only |
| supervisor_flutter / admin_web | 151 / 152 | admin devtools_options.yaml only |

Android/iOS/web/desktop configurations within each pair had no source differences
in that comparison. This does not prove native execution or justify deleting
folders. All are retained. Primary locks/tests now intentionally differ from
duplicates; the comparison script ignores generated/cached files.

## Actual verification

Verified environment: Windows, Node 20.17.0, npm 11.4.1, Java 17.0.15,
Flutter 3.35.4 / Dart 3.9.2. Installed core versions include NestJS 10.4.22,
TypeScript 5.9.3, Firebase Admin 12.7.0, Firebase CLI 13.35.1,
Firebase Core Flutter 3.15.2, Auth 5.7.0, Firestore 5.6.12,
RTDB 11.3.10 and Storage 12.4.10.

Commands below are from png2, unless a working directory is specified.

| Check / command | Actual result |
| --- | --- |
| Root npm install --ignore-scripts --no-audit --no-fund | Passed; CLI/tool lock generated |
| backend npm install --ignore-scripts --no-audit --no-fund | Passed; backend lock generated |
| backend npm ci --ignore-scripts --offline --no-audit --no-fund | Passed clean reinstall: 808 packages from cache |
| npm ls and backend npm ls --depth=0 | Resolved dependency trees; no unmet peer dependency error |
| backend npm run build | Passed against genuine library declarations |
| backend npm run lint | Passed TypeScript analysis |
| npm run typecheck | Passed backend/shared TS source analysis |
| backend npm test | 21/21 passed in 6 suites |
| backend npm run test:contracts | 5/5 shared TS contract/policy cases passed |
| backend npm run test:e2e | 1/1 real Nest HTTP foundation case passed; Firebase overridden |
| npm run test:isolation | 2/2 local runner configuration cases passed |
| npm run emulators | Auth, Firestore, RTDB, Storage and UI started successfully |
| npm run verify:emulators | All four required loopback services reachable |
| npm run test:emulators | Passed real emulator sign-in/token, Firestore/RTDB/Storage save/read, client role-write denial and test cleanup |
| Shared Dart package flutter pub get | Passed; shared lockfile generated |
| Shared package flutter analyze | No issues found |
| Shared package flutter test | 19/19 passed, including 6 new contract/config/API cases |
| Each primary app flutter analyze --no-pub | No issues found in all four; two passenger notices corrected |
| Each primary app flutter test --no-pub | 2/2 per app, 8/8 total |
| Each primary app flutter build web --no-pub --no-web-resources-cdn | All four passed, including final shared startup adjustment |
| node scripts/browser-foundation.mjs | All four real Flutter entrypoints booted in headless Edge using local backend/emulators |
| Modified JS/TS/JSON Prettier check | Passed |
| git diff --check | Passed |
| git check-ignore .env backend/.env credentials.serviceAccount.json | All excluded |
| Local runner with emulators stopped | Failed clearly as expected; no fallback startup |

Important limits:
- The 21 backend tests include 6 preserved prototype service tests with mocked
  Firebase; their old payment/rate expectations do not verify safe activation.
- The 19 Dart tests include 13 pre-existing model/test-local workflow cases;
  they are not genuine four-role operational integration tests.
- HTTP e2e exercises live Nest routing/envelopes/quarantine with Firebase mocked.
  The separate smoke test exercises real local emulators using a unique test user,
  local .invalid email and exact test paths, then deletes those records.
- Browser check exercises actual Flutter initialization/configuration for four
  entrypoints, not four authenticated operational role flows. It blocks non-local
  data/auth APIs but permits versioned Firebase JS 11.9.1 and static font downloads
  required by FlutterFire/Flutter. It uses existing Playwright/Edge tooling; no
  Playwright runtime dependency was introduced.
- No physical device, Android/iOS release, native desktop release, live tracking,
  payments, messaging, emergency response or production test passed by implication.

## Exact blocker and remaining work

**Windows desktop plugin setup:** primary app flutter pub get resolves/downloads
dependencies but exits 1 at plugin symlink generation:
"Building with plugins requires symlink support. Please enable Developer Mode..."
No Windows setting was changed. Web analysis/tests/builds work with --no-pub using
the successfully resolved package configuration. This is not a clean native desktop
setup pass. Developer Mode/appropriate symlink privileges are still needed for
normal desktop plugin generation. Android/iOS signing/device checks were not run.

Firebase CLI prints unauthenticated/demo-project metadata warnings; no login is
required to run the verified emulators. Dependencies also emitted existing
deprecation notices. Compatibility was verified through resolution/builds/tests;
an independent vulnerability/advisory audit was not performed.

Production credentials, Firebase/GCP project ownership/IAM/hosting decisions and
provider accounts are intentionally not configured. Approved PNG fares, tax/
invoice treatment, cash/credit verification, commissions, service coverage,
staff/airport scope and emergency/privacy/retention policy still need operator
decisions. These do not block further emulator-based development.

### Recommended Batch B

1. Implement real Firebase Auth account/session lifecycle in the selected apps,
   passenger-only public registration and protected staff provisioning. Establish
   server-managed canonical claims and account suspension/revocation behavior.
2. Activate guarded routes individually with service-level organization/airport,
   customer and driver-assignment checks. Add emulator-backed positive/negative
   role and record-scope tests before relaxing any direct-client read rules.
3. Adopt canonical pipes/DTOs at booking/quotation service boundaries, remove
   legacy numeric/snake_case/direct-client business mutations and serialize
   authorized v1 responses. Do not adapt missing records with invented fields.
4. Bind quotes to identity/input/approved rate version and consume them atomically
   with idempotency and revision handling. Keep pricing unavailable until approved
   tariffs exist; use explicitly isolated test rates.
5. Replace legacy automatic assignment, payment confirmation and OTP behavior
   with transactional dispatch/acceptance/state/verification operations. Complete
   trip/resource/audit consistency; never infer paid from booking confirmation.
6. Reconnect preserved four-role screens to authoritative state, then enable each
   app entrypoint after its safe workflow tests pass. Remove the foundation guard
   only as part of verified per-route activation, not via a permissive flag.
7. Implement truthful/durable offline behavior and selected provider integrations
   in later batches with approved policies/credentials.

## Documentation and local commands

- docs/local-development.md: install/start/check commands and Windows limitation.
- docs/contracts-v1.md: canonical field/state/scope definition and migration boundary.
- docs/application-structure.md: primary apps and actual native/duplicate comparison.
- docs/configuration.md: active local-only settings.
- README.md: current foundation status above historical product architecture.

When changing shared TS contracts, rebuild them with
npm --prefix backend run build:contracts before restarting backend watch mode.
For optional browser checks, an installed Playwright package and Edge are needed;
the app/backend do not depend on them.

## Modified files

The following inventory includes modified/deleted tracked files and new source,
configuration, locks, tests and documentation. Build/cache/emulator logs are
ignored. Duplicated app startup/native config edits apply the same safety boundary
and do not create additional operational implementations.

- .env.example
- .firebaserc
- .gitignore
- AEROTRANS_PNG2_BATCH_A_REPORT.md
- README.md
- apps/admin_web/android/app/src/debug/AndroidManifest.xml
- apps/admin_web/lib/main.dart
- apps/admin_web/pubspec.lock
- apps/admin_web/test/widget_test.dart
- apps/client_flutter/android/app/google-services.json
- apps/client_flutter/android/app/src/debug/AndroidManifest.xml
- apps/client_flutter/lib/blocs/auth/auth_event.dart
- apps/client_flutter/lib/firebase_options.dart
- apps/client_flutter/lib/main.dart
- apps/client_flutter/lib/ui/screens/auth/register_screen.dart
- apps/control_room_flutter/android/app/google-services.json
- apps/control_room_flutter/android/app/src/debug/AndroidManifest.xml
- apps/control_room_flutter/lib/firebase_options.dart
- apps/control_room_flutter/lib/main.dart
- apps/control_room_web/android/app/google-services.json
- apps/control_room_web/android/app/src/debug/AndroidManifest.xml
- apps/control_room_web/lib/firebase_options.dart
- apps/control_room_web/lib/main.dart
- apps/control_room_web/pubspec.lock
- apps/control_room_web/test/widget_test.dart
- apps/corporate_web/android/app/google-services.json
- apps/corporate_web/android/app/src/debug/AndroidManifest.xml
- apps/corporate_web/lib/firebase_options.dart
- apps/corporate_web/lib/main.dart
- apps/driver_flutter/android/app/google-services.json
- apps/driver_flutter/android/app/src/debug/AndroidManifest.xml
- apps/driver_flutter/lib/firebase_options.dart
- apps/driver_flutter/lib/main.dart
- apps/driver_mobile/android/app/google-services.json
- apps/driver_mobile/android/app/src/debug/AndroidManifest.xml
- apps/driver_mobile/lib/firebase_options.dart
- apps/driver_mobile/lib/main.dart
- apps/driver_mobile/pubspec.lock
- apps/driver_mobile/test/widget_test.dart
- apps/operator_web/android/app/google-services.json
- apps/operator_web/android/app/src/debug/AndroidManifest.xml
- apps/operator_web/lib/main.dart
- apps/passenger_web/android/app/google-services.json
- apps/passenger_web/android/app/src/debug/AndroidManifest.xml
- apps/passenger_web/lib/blocs/auth/auth_event.dart
- apps/passenger_web/lib/firebase_options.dart
- apps/passenger_web/lib/main.dart
- apps/passenger_web/lib/ui/screens/auth/register_screen.dart
- apps/passenger_web/pubspec.lock
- apps/passenger_web/test/widget_test.dart
- apps/security_mobile/android/app/src/debug/AndroidManifest.xml
- apps/security_mobile/lib/main.dart
- apps/supervisor_flutter/android/app/src/debug/AndroidManifest.xml
- apps/supervisor_flutter/lib/main.dart
- backend/package-lock.json
- backend/package.json
- backend/src/app.module.ts
- backend/src/app.setup.ts
- backend/src/common/decorators/roles.decorator.ts
- backend/src/common/filters/http-exception.filter.ts
- backend/src/common/guards/auth.guard.spec.ts
- backend/src/common/guards/auth.guard.ts
- backend/src/common/guards/foundation.guard.ts
- backend/src/common/guards/roles.guard.ts
- backend/src/common/interceptors/transform.interceptor.ts
- backend/src/config/local-environment.spec.ts
- backend/src/config/local-environment.ts
- backend/src/contracts/canonical.pipe.ts
- backend/src/contracts/contracts.controller.ts
- backend/src/contracts/contracts.spec.ts
- backend/src/firebase/firebase.service.ts
- backend/src/health.controller.ts
- backend/src/main.ts
- backend/src/scripts/seed.ts
- backend/src/typings.d.ts
- backend/test/foundation.e2e-spec.ts
- backend/test/jest-e2e.json
- backend/tsconfig.build.json
- backend/tsconfig.json
- database.rules.json
- docs/api-contracts.md
- docs/application-structure.md
- docs/configuration.md
- docs/contracts-v1.md
- docs/local-development.md
- firebase.json
- firebase.local.json
- firestore.rules
- infrastructure/firebase.hosting.example.json
- package-lock.json
- package.json
- packages/api-client/src/index.ts
- packages/offline-sync/src/index.ts
- packages/png_transfer_flutter_core/.gitignore
- packages/png_transfer_flutter_core/lib/config/app_config.dart
- packages/png_transfer_flutter_core/lib/config/local_firebase.dart
- packages/png_transfer_flutter_core/lib/models/contracts_v1.dart
- packages/png_transfer_flutter_core/lib/png_transfer_flutter_core.dart
- packages/png_transfer_flutter_core/lib/repositories/booking_repository.dart
- packages/png_transfer_flutter_core/lib/services/png_api_client.dart
- packages/png_transfer_flutter_core/pubspec.lock
- packages/png_transfer_flutter_core/pubspec.yaml
- packages/png_transfer_flutter_core/test/contracts_v1_test.dart
- packages/types/fixtures/booking.v1.json
- packages/types/fixtures/definition.v1.json
- packages/types/fixtures/error.v1.json
- packages/types/fixtures/quotation.v1.json
- packages/types/package.json
- packages/types/src/index.ts
- packages/types/src/legacy.ts
- packages/types/src/requests.ts
- packages/types/src/v1.ts
- packages/types/test/contracts.test.cjs
- packages/types/tsconfig.json
- scripts/browser-foundation.mjs
- scripts/compare-apps.mjs
- scripts/emulator-smoke.test.mjs
- scripts/local.mjs
- scripts/local.test.mjs
- storage.rules
- tsconfig.json

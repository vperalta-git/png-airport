# AeroTrans PNG2 hosted test foundation

Date: 10 November 2026.

## Completed

- Preserved NestJS/Firebase/Flutter, local emulator security and the separate
  offline APK. No live Firebase configuration or operational data was changed.
- Created approved isolated Firebase project `aerotrans-png-test-7d7128`, its web
  application, and Firestore default database in `asia-southeast1` with deletion
  protection. Auth and Firestore APIs are enabled; billing was not upgraded.
- Created a separate Vercel NestJS API project, `aerotrans-png-test-api-7d7128`,
  configured for the backend directory and Node 22. No API deployment is claimed.
- Added a narrowly scoped hosted-test runtime. Other project IDs, the supplied
  live project, mixed emulator settings and incorrect credentials fail validation.
- Added explicit HTTPS CORS origins, runtime identity in health responses, and
  server-only credential configuration without embedding keys in source.
- Added public Flutter web compile configuration and validation. The client checks
  backend identity before initializing Firebase. Local/public preview behavior
  remains available when hosted configuration is absent.
- Kept hosted web and native configuration separate. Existing APK files have not
  been rebuilt or installed during this hosted-web task.

## Modified source

- `backend/src/config/runtime-environment.ts` and its focused specification
- `backend/src/firebase/firebase.service.ts`
- `backend/src/app.setup.ts`, `health.controller.ts`, `main.ts`
- `backend/vercel.json`, `.env.staging.example`
- `packages/png_transfer_flutter_core/lib/config/app_config.dart`, `local_firebase.dart`
- `packages/png_transfer_flutter_core/lib/connected/connected_review_app.dart`,
  `connected_website_landing.dart`
- `packages/png_transfer_flutter_core/lib/services/png_api_client.dart`
- `packages/png_transfer_flutter_core/test/connected_review_app_test.dart`
- `scripts/prepare-web-config.mjs`, `public-web-config.test.mjs`, `vercel-build-web.sh`
- `docs/hosted-test.md`, `docs/website.md`, this report and `update.txt`

Provisioning metadata and SDK configuration remain ignored under `.local-tools`.
No generated private key, login token or test password is included in publication.

## Verification

- `npm --prefix backend run build`: passed.
- `npm --prefix backend test -- --silent`: 7 suites, 39 tests passed.
- Shared Flutter package `flutter test --no-pub`: 48 passed, 5 offline-build-only
  tests skipped under the normal connected test configuration.
- `flutter analyze --no-pub`: no issues found.
- Focused connected Flutter UI/startup regression: 7 passed after final safeguards.
- `node --test scripts/public-web-config.test.mjs`: 1 passed.
- `npm run test:isolation`: 2 passed. An initial sandbox child-process EPERM was
  resolved by rerunning this check with the permitted execution profile.
- `npm --prefix backend run test:e2e -- --silent`: 1 suite / 1 test passed.
  This uses a mocked Firebase service and checks the actual Nest HTTP foundation;
  it is not a cloud or four-role integration test.
- Hosted-mode `flutter build web --release --no-pub --target
  lib/main_connected.dart --dart-define=AEROTRANS_CONNECTED_REVIEW=true
  --dart-define-from-file=<ignored-compile-fixture> --no-web-resources-cdn`:
  passed in 60.6 seconds. The fixture uses a reserved `.invalid` API origin and
  placeholder public SDK values, makes no service calls, and must not be deployed.

## Remaining blockers

Standard Firebase Authentication needs console activation and Email/Password
enablement in the **new test project**. An API initialization attempt returned
`BILLING_NOT_ENABLED`; no billing upgrade was performed.

Automatic approval review rejected executing the key provisioning/upload script:
although test setup was authorized, transferring a private service-account key to
Vercel requires specific authorization. The script did not execute, so no service
account or key was created by that action. A user approval question is pending.

API deployment, backend credentials, test account/fleet provisioning, public
frontend activation and remote four-role acceptance remain incomplete. The current
hosted website is intentionally kept in preview until these checks can be completed.
No cloud authentication, real-device, production or payment-provider test passed
during this task, and none is claimed.

## Recommended next step

Complete the two pending setup actions, deploy the isolated backend, and verify
customer quote/booking, dispatch assignment, driver OTP/trip progress, supervisor
activity and role/scope denial using separate test accounts. Configure and deploy
the frontend only after backend readiness. Then register the Android test app and
build a separately labelled hosted test APK using that same verified backend.

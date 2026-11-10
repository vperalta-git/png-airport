# AeroTrans PNG2 hosted test report

Updated: 10 November 2026. Architecture: NestJS / Firebase / Flutter.

## Completed environment

- Firebase test project: `aerotrans-png-test-7d7128` (AeroTrans PNG Test).
  The live project `airport-png-c866b` remains untouched.
- Registered a web app, activated standard Email/Password Auth, and authorized the
  website domain. No billing upgrade was enabled.
- Firestore `(default)` is in `asia-southeast1`, with deletion protection and
  deny-all direct-client rules. Operational access goes through NestJS.
- After explicit user approval, created a dedicated test service account with
  Firebase Authentication Admin and Cloud Datastore User roles only in this test
  project. Its key is a sensitive variable in the separate Vercel API project.
  The private key was not saved locally, printed or committed.
- Deployed NestJS to https://aerotrans-png-test-api-7d7128.vercel.app using Node 22
  and the backend directory. Public HTTPS health identifies the staging project.
- Created four labelled test accounts and two test vehicles. Generated passwords
  are in ignored `.local-tools/hosted-test/accounts.json`, never source.
- Configured the existing frontend with public test SDK values and the verified
  test API URL. Server credentials are excluded from the frontend.
- Local emulator setup, offline APK and existing connected APK are preserved.
  No new APK build, installation or native acceptance is claimed in this task.

## Source changes

Explicit local/staging runtime validation rejects live IDs, conflicting credentials,
mixed emulator/cloud configuration and unconfigured RTDB/Storage providers. Added
HTTPS CORS and runtime identity in health responses. Flutter verifies backend
identity before Firebase initialization; missing configuration retains the public
preview, and failed services never create fake users or offline success.

Fixed Vercel startup by removing an incompatible named entrypoint export. Repeated
Flutter builds now use a pinned 3.35.4 SDK outside Vercel's restored cache, which
had incomplete SDK Git metadata resolving to the app commit. Inherited Git checkout
overrides are cleared. No replacement backend or runtime dependency was introduced.

Added opt-in real API acceptance and optional Playwright browser acceptance. Tests
read ignored account sheets; authentication tokens remain in memory.

Modified: backend/src/config/runtime-environment.ts and its specification;
backend/src/firebase/firebase.service.ts; backend/src/app.setup.ts;
backend/src/health.controller.ts; backend/src/main.ts; backend/vercel.json;
.env.staging.example; shared Flutter lib/config/app_config.dart,
lib/config/local_firebase.dart, lib/connected/connected_review_app.dart,
lib/connected/connected_website_landing.dart, lib/services/png_api_client.dart,
test/connected_review_app_test.dart; scripts/prepare-web-config.mjs,
scripts/public-web-config.test.mjs, scripts/vercel-build-web.sh,
scripts/test-hosted-review.mjs, scripts/test-hosted-web.mjs; README.md; docs/hosted-test.md;
docs/website.md; update.txt; this report.

Provisioning metadata, account sheets, generated SDK values and evidence remain
ignored under .local-tools. Source publication uses the separate clean checkout;
original repository history, index and origin are preserved.

## Actual verification

- Backend build passed, including after the Vercel entrypoint fix.
- Backend unit tests: 7 suites / 39 passed.
- Nest HTTP foundation: 1 suite / 1 passed with mocked Firebase; not a cloud test.
- Shared Flutter tests: 48 passed; 5 offline-build-only tests skipped with normal
  connected flags. Focused connected regression after final safeguards: 7 passed.
- Flutter analysis clean. Local hosted-mode release web compilation passed with
  non-network fixtures, which were not deployed.
- Public configuration security test: 1 passed. Local isolation tests: 2 passed.
- Real hosted API acceptance passed: HTTPS identity and CORS; all four Firebase
  sign-ins; customer registration; anonymous/role/ownership denials; authoritative
  integer-PGK quotes; idempotent booking; manual assignment and availability;
  driver acceptance/progress; wrong and replayed OTP rejection; completed trip
  history; cancellation; supervisor summary, users and audit responses.
- A completed trip retained payment PENDING. No successful provider transaction
  was simulated. Acceptance registration/bookings are labelled test records.
- Real signed-in customer direct Firestore read denied (403); unapproved browser
  origin received no CORS permission.
- Vercel website deployment READY at https://png-airport-kappa.vercel.app.
  The hosted Flutter release compiled in 51.4 seconds; total build was about
  two minutes. Verified alias: png-airport-kappa.vercel.app.
- Real Edge browser acceptance: 5 cases passed (four roles at 1440px and Customer
  at 390px), covering Firebase login, server-authorized workspace, all required
  workspace API reads and account switching. Supervisor management loaded users;
  a Driver selecting the Supervisor card still received the Driver workspace.
  No browser runtime errors or localhost/live-project requests were observed.
  These browser checks do not claim every booking action was clicked through;
  the full booking-to-completion workflow was exercised by the real API test.
- Deployment audit passed: only public configuration on the frontend; the private
  key is a sensitive, production-target variable in the separate test API project.
  No private-key marker or test service-account email appeared in public app JS.
- Evidence: ignored .local-tools/hosted-test/api-acceptance.json,
  isolation-acceptance.json, deployment-audit.json and browser/results.json.
  Browser screenshots were visually reviewed for phone layout and management.

## Remaining limits and next phase

Hosted Android needs a registered Android test app, matching native SDK settings,
a fresh APK build and physical-phone acceptance. Hosted configuration currently
supports web only; existing APKs retain their local/USB backend configuration.

Commercial fares still need operator approval. Only labelled test rates are enabled.
Payments, provider notifications, RTDB tracking and Storage uploads are not active
integrations. No production, provider or device test is claimed.

The Vercel install reported existing npm advisories. Review dependency updates
separately; no forced or broad upgrade was attempted. Production readiness also
needs approved scope/rules, recovery/invitation policy, abuse protection, monitoring
and retention decisions.

The pinned Flutter renderer omitted bottom-navigation labels from the browser
semantics tree. The Supervisor browser check used its visible mouse target;
screen-reader accessibility still needs review.

Next: supervisor website acceptance using four test accounts, then one hosted-test
Android APK connected to this same verified backend. Keep the live project separate
until its data model and production rollout are reviewed and explicitly approved.

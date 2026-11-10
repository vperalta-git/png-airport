# Isolated hosted test environment

Status: 10 November 2026. Setup is incomplete; hosted login and bookings have not
passed acceptance. Do not announce this environment as ready for testers.

The user identified `airport-png-c866b` as a live project. Its data and settings
must not be changed for this demo. A separately approved Firebase project,
`aerotrans-png-test-7d7128` (AeroTrans PNG Test), now exists. It has a registered
web app and a Firestore default database in `asia-southeast1`, with deletion
protection enabled. No billing upgrade was enabled.

The Vercel frontend project remains `png-airport`, with repository root as its
root directory. A separate API project, `aerotrans-png-test-api-7d7128`, has been
created with root directory `backend`, framework NestJS and Node 22. Creating
these resources does not mean that an API has been deployed.

## Runtime configuration

Local scripts still require all four loopback emulators and project
`demo-aerotrans-png2`. They reject hosted credentials and production configuration.
The backend's new runtime configuration additionally accepts `AEROTRANS_ENV=staging`
only with the exact approved test project. It rejects the live project, mixed
emulator configuration, ambient credential overrides and unconfigured RTDB/Storage
URLs. See `.env.staging.example` for server variable names.

Hosted NestJS requires a dedicated test-project service-account JSON in the
server host's sensitive `FIREBASE_SERVICE_ACCOUNT_KEY` setting. The intended
project-level permissions are Firebase Authentication Admin and Cloud Datastore
User, only within the test project. This key must never enter a browser build,
Git history, frontend environment, handoff, console output or account sheet.
Creating this key and transferring it to Vercel is pending specific user approval.
No key has been created or uploaded by the rejected setup command.

The frontend build accepts `AEROTRANS_PUBLIC_CONFIG`, containing JSON with exactly:

- `AEROTRANS_ENV`: `staging`
- `FIREBASE_PROJECT_ID`: `aerotrans-png-test-7d7128`
- `API_BASE_URL`: the verified HTTPS test API origin, without a path
- `FIREBASE_WEB_API_KEY`: public web SDK API key
- `FIREBASE_WEB_APP_ID`: registered test web app ID
- `FIREBASE_AUTH_DOMAIN`: `aerotrans-png-test-7d7128.firebaseapp.com`
- `FIREBASE_MESSAGING_SENDER_ID`: test SDK sender ID

`scripts/prepare-web-config.mjs` validates the public payload, rejects unexpected
fields and server credential content, and generates Dart defines during the build.
Absent this variable, public deployments retain the informational preview and
disabled sign-in. They never probe a website visitor's localhost. A configured
build verifies the API's project and runtime identity before Firebase initialization;
unavailable services produce an honest error, without offline or fake-user fallback.

This hosted configuration supports **web only**. Native APKs still use their
existing local setup. Hosted native support needs Android app registration and
matching Firebase configuration; supplying a web app ID to Android is rejected.

## Pending activation and deployment

1. In the **new test project**, open Authentication, click Get started, and enable
   Email/Password. Use standard Firebase Authentication. Stop if billing is required.
   The paid Identity Platform initialization endpoint was not used successfully
   and no billing changes were made.
2. Obtain specific approval for exporting the dedicated test key to Vercel, then
   provision it as a sensitive variable in the separate API project only.
3. Publish deny-all direct-client Firestore rules to the new test project. Keep
   operations behind NestJS authorization; never deploy this batch to the live project.
4. Deploy the test API and verify its actual HTTPS health response, CORS and
   unauthenticated rejection. Do not derive a working URL solely from a project name.
5. Create clearly labelled test accounts and fleet records in the new project.
   Do not repurpose the strict emulator-only seeding script for cloud access.
6. Configure the verified API URL and public test Firebase SDK values on the
   frontend, then deploy and run four-role browser acceptance with separate accounts.

Test fares remain explicitly labelled, opt-in fixture rates; payments remain
unverified/PENDING without a real provider. RTDB tracking, Storage uploads and
provider notifications are outside this hosted test batch. No live data migration,
commercial tariffs, or successful payment simulations are included.

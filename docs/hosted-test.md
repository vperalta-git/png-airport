# Isolated hosted test environment

Updated: 10 November 2026. Online test environment with real Firebase Auth,
server authorization and persistent Firestore. No real payment collection.

| Component | Configuration |
| --- | --- |
| Firebase project | aerotrans-png-test-7d7128 |
| Website | https://png-airport-kappa.vercel.app |
| NestJS API | https://aerotrans-png-test-api-7d7128.vercel.app |
| API Vercel project | aerotrans-png-test-api-7d7128, backend root, NestJS, Node 22 |
| Frontend Vercel project | png-airport, repository root, static Flutter Web |
| Database | Firestore (default), asia-southeast1, deletion protection |
| Direct client data access | Denied; operational access goes through NestJS |

The live project airport-png-c866b was not changed. The user approved this separate
setup, Auth activation and storing its dedicated test key in Vercel sensitive
backend settings. No key was saved locally or added to the frontend.

## Configuration

Local scripts still require four loopback emulators and demo-aerotrans-png2. They
reject hosted credentials. Backend staging mode accepts only the approved test
project and refuses mixed cloud/emulator settings. See .env.staging.example.
ALLOWED_ORIGINS explicitly lists the website HTTPS origin.

The dedicated account has Firebase Authentication Admin and Cloud Datastore User
roles only in the test project. Its JSON belongs only in the API host's sensitive
FIREBASE_SERVICE_ACCOUNT_KEY variable. Never put it in Git, frontend settings,
build defines, screenshots or handoffs.

Frontend AEROTRANS_PUBLIC_CONFIG is public JSON containing exactly:

- AEROTRANS_ENV: staging
- FIREBASE_PROJECT_ID: aerotrans-png-test-7d7128
- API_BASE_URL: the verified HTTPS API origin above
- FIREBASE_WEB_API_KEY: public test web SDK key
- FIREBASE_WEB_APP_ID: registered test web app ID
- FIREBASE_AUTH_DOMAIN: aerotrans-png-test-7d7128.firebaseapp.com
- FIREBASE_MESSAGING_SENDER_ID: test SDK sender ID

scripts/prepare-web-config.mjs rejects unexpected fields and server credentials.
Without this setting, builds retain the informational preview with disabled login,
without probing a visitor's localhost. Configured builds verify backend identity
before Firebase initialization; errors never fall back to fake accounts or bookings.

Hosted settings currently support WEB ONLY. Register and configure an Android test
app before building a hosted APK. Existing native connected APKs retain local mode.

## Accounts and acceptance

Four accounts have server-enforced roles: PASSENGER (Customer), DISPATCHER (Control
Room), DRIVER and SUPERVISOR. Generated passwords are only in the ignored local
file .local-tools/hosted-test/accounts.json. Share test credentials privately.
Selecting a workspace card never grants that role.

Real API acceptance, which creates labelled records only in the test project:

    node scripts/test-hosted-review.mjs --allow-test-writes

The script requires ignored test SDK/account sheets and pins its Firebase project
and API origin. It checks identity before mutations and retains tokens in memory.
Acceptance creates a labelled registration, completed booking and cancelled booking
as audit evidence. It does not delete existing records or confirm payment.

Optional browser acceptance using existing local Playwright and Microsoft Edge:

    node scripts/test-hosted-web.mjs

Evidence remains ignored under .local-tools/hosted-test. See the hosted test report
for actual results. Commercial prices and tax decisions, payment providers,
notifications, tracking and uploads remain unconfigured. This is a review system,
not an approved production release.

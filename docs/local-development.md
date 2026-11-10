# Local development

PNG2 uses NestJS, Firebase and Flutter. Only isolated emulator mode is enabled;
no Firebase login, cloud service account or production data is needed.

For the current four-role Android demo, use [android-demo.md](android-demo.md).
The earlier [Batch A report](../AEROTRANS_PNG2_BATCH_A_REPORT.md) records the original
foundation work. Four primary apps now launch authenticated workflows; duplicate
and expansion apps keep the foundation gate.

## Prerequisites and install

Verified tools: Node 20.17.0, Java 17.0.15 for Firebase, Flutter 3.35.4 / Dart 3.9.2.
Firebase CLI is pinned to 13.35.1. Android uses the installed SDK and Android Studio
JBR; project Gradle/Kotlin versions are aligned to the installed Flutter toolchain.

From PNG2:

```powershell
npm ci --ignore-scripts
npm --prefix backend ci --ignore-scripts
npm --prefix backend run build
```

Resolve the shared Flutter package and each selected app with `flutter pub get`.
On this machine Windows desktop plugin generation needs unavailable symlink
support. Packages resolved before that warning, permitting --no-pub tests and
Android/web builds. This is not a claim that fresh desktop builds work.

## Start services

```powershell
npm run emulators
```

In another terminal:

```powershell
npm run backend
```

The ordinary backend leaves commercial pricing unconfigured. For explicit local
test fares and demo accounts/fleet, follow the Android guide:
`npm run demo:backend`, then `npm run demo:setup`.

The demo command compiles once and runs the same NestJS server without watching
files. This prevents snapshot/test/document writes from interrupting demonstration
requests. The ordinary backend command retains development watch mode.

The runner derives emulator endpoints from firebase.local.json and rejects
conflicting cloud IDs, endpoints and credentials. Unset conflicting variables;
do not pass production values. A backend .env can instead be copied from
.env.example for direct backend commands. Real environment files are ignored.

Project: demo-aerotrans-png2. All service listeners use loopback:

| Service | Port |
| --- | --- |
| NestJS | 8080 |
| Auth | 9099 |
| Firestore | 8085 |
| RTDB | 9000 |
| Storage | 9199 |
| Emulator UI | 4000 |
| Emulator hub | 4400 |

The emulator runner imports the ignored .emulator-data/runtime snapshot when it
exists and exports there on graceful exit. Use `npm run demo:save` before shutdown.
Forced termination may leave a Java emulator process holding its port; identify
that specific local demo process before stopping it. Do not change ports or kill
unrelated processes just to bypass a conflict.

## Flutter

Maintained folders: passenger_web, control_room_web, driver_mobile, admin_web.

```powershell
npm run flutter -- passenger_web chrome
npm run flutter -- control_room_web chrome
npm run flutter -- driver_mobile chrome
npm run flutter -- admin_web chrome
```

Choose one app per terminal. Chrome ports are 5001–5004. An Android emulator serial
such as emulator-5554 selects 10.0.2.2 explicitly. Real-phone serials use
127.0.0.1 and require `npm run demo:phone` USB forwarding first. Firebase automatic
host remapping is disabled so the configured host is preserved.

Startup validates local backend identity and all four services, initializes the
demo Firebase app, then configures SDK emulator endpoints. Failure blocks startup.
The four primary apps use canonical API workflows. Existing legacyMain builders,
old screens/BLoCs and future domain modules remain unactivated; no cloud or fake
session fallback is allowed.

Operational state is authoritative in the API/Firestore. Direct client Firebase
rules remain deny-all. Firebase Auth SDK email/password sign-in produces the ID
token; the API checks claims, scope and active profile. Unsupported legacy routes
remain unavailable, including fake payment/provider/offline-sync paths.

## Verification

```powershell
npm run test:isolation
npm run typecheck
npm --prefix backend run build
npm --prefix backend test
npm --prefix backend run test:contracts
npm --prefix backend run test:e2e
npm run verify:emulators
npm run test:emulators
npm run demo:test
```

The emulator smoke test creates and removes its own Auth/Firestore/RTDB/Storage
fixtures. The four-role integration uses separate real emulator accounts and a
random organization, verifies API workflows and permissions, and removes only
its test data. It requires the four emulators.

Run `flutter test --no-pub` in the shared package and four primary apps.
Build APKs with `npm run demo:android`; see the Android guide for native acceptance
and the optional compiled Flutter browser workflow check.

No production, commercial tariff, merchant, messaging or GPS integration is
enabled or verified. Historical infrastructure files are examples, not deployment
instructions for this local runtime.

# Four-role Android demo

This page covers the retained connected/emulator APKs. For the separately exported
standalone offline apps, use [offline-demo.md](offline-demo.md).

This is an isolated local demonstration for Lae / Nadzab, Papua New Guinea.
The four APKs share the existing NestJS backend and Firebase Emulator Suite.
Bring this computer and keep the phone connected by USB throughout the demo.
These APKs do not connect to a deployed backend or production Firebase.

## Start the demo

The local services were left running at implementation handoff. Check
`npm run verify:emulators` and http://127.0.0.1:8080/api/v1/health first. If both
are ready, skip starting duplicate service processes and proceed to phone setup.
The terminal instructions below apply to a fresh start.

Open PowerShell in `C:\Users\Vionne\Documents\PNG Airport Transfer\png2`.

Terminal 1 (leave running):

```powershell
npm run emulators
```

Terminal 2 (leave running):

```powershell
npm run demo:backend
```

This command compiles once and runs the compiled NestJS server without a file
watcher, so saving snapshots or editing handoff files cannot restart a request.
Use `npm run backend` separately when actively developing with automatic rebuilds.

Terminal 3:

```powershell
npm run verify:emulators
npm run demo:setup
npm run demo:phone -- --install
```

Enable Developer options and USB debugging on the Android phone. Accept the
computer's USB debugging authorization prompt and keep the phone unlocked for
installation. For several phones, repeat the phone command with
`--serial <adb-device-id> --install` for each phone.

The phone helper forwards only backend 8080, Auth 9099, Firestore 8085, RTDB 9000
and Storage 9199. Services remain bound to computer loopback. Re-run the command
after disconnecting/reconnecting USB. All four apps can coexist on one phone;
each keeps its own sign-in session. Use Android's recent-apps view to switch roles.

Open `.local-tools/demo/accounts.json` locally for the generated email/password
pairs. This ignored file contains emulator credentials; keep it out of handoffs,
screenshots, commits and shared reports. Setup creates four explicitly named
DEMO accounts and two DEMO vehicles. It does not insert bookings.

APK files are in `.local-tools/demo/apks/`:

| App | APK | Android package |
| --- | --- | --- |
| Customer | aerotrans-customer-demo.apk | com.pngtransfer.png_transfer_client.demo |
| Control Room | aerotrans-control-room-demo.apk | com.pngtransfer.png_transfer_control_room.demo |
| Driver | aerotrans-driver-demo.apk | com.pngtransfer.png_transfer_driver.demo |
| Supervisor | aerotrans-supervisor-demo.apk | com.pngtransfer.png_transfer_supervisor.demo |

The verified artifacts contain ARM32 and ARM64 libraries, minimum Android API 24
(Android 7), target API 36. They are debug builds, about 126 MB each. They are not
store releases. Labels and the yellow demo banner distinguish them from real operations.

## Demonstration walkthrough

1. Customer: sign in or create a customer account. Choose an airport-to-Lae
   transfer, enter an address, future PNG pickup time, passenger names and luggage.
   Get the server quote, then confirm the reservation.
2. Control Room: open the new reservation and assign the available demo driver
   and matching demo vehicle. Refresh when necessary; lists poll every five seconds.
3. Customer: open the reservation to see the assigned driver, vehicle and pickup code.
4. Driver: open the assigned trip, accept with all four pre-trip checks, depart,
   arrive at the pickup point and enter the customer's code. Start the transfer,
   mark arrival at destination and complete it.
5. Customer: review trip status/history. Payment remains pending.
6. Supervisor: review summaries and audit records; create/edit staff, change driver
   duty and manage vehicles. Reissue a locked/expired pickup code at the pickup
   stage if needed. Close completed reservations.
7. Create another reservation to demonstrate early cancellation or reassignment.
   Driver reassignment is permitted only before departure; it requires fresh
   acceptance by the newly assigned driver.

Use test names and addresses only. Status updates are manual driver reports.
There is no GPS, flight, SMS, WhatsApp, merchant or notification provider in this demo.
No map movement, payment confirmation or delivery notification is simulated.

## Pricing and data integrity

`npm run demo:backend` explicitly enables isolated test fares: sedan PGK 100.00
and SUV PGK 150.00. They are server fixtures, not approved tariffs. The zero test
tax component is not a business tax policy. Normal `npm run backend` leaves
pricing unconfigured unless the explicit demo-rate environment flag is supplied.
No commercial tariffs are inferred.

The backend binds bookings to a customer-owned, unexpired quotation. It atomically
consumes quotes and retains idempotency keys, locks busy drivers/vehicles, checks
revisions and enforces role/scope/assignment permissions. Passenger verification
is server-side, single-use, expires and locks after five incorrect attempts.
Only the owning customer sees the code. Generic trip status updates cannot verify
a passenger or mark payment paid.

When saving a reservation has an uncertain network outcome, keep the form open
and use **Retry same reservation**. It retains the same intent and key.
After process termination, check the reservation list before starting a new booking;
persistent client recovery of an interrupted form is future work.

## Save and restart

```powershell
npm run demo:save
```

This exports only the running local emulators into ignored
`.emulator-data/runtime/`. The current emulator runner imports that snapshot at
startup and exports on graceful exit. Save before shutting down the computer.
Forced process termination may lose changes since the last snapshot.

Keep the accounts file with the emulator snapshot on this computer. Running setup
again reuses its generated passwords and refuses to overwrite records it does
not own. Existing operational/demo bookings are never auto-replaced by setup.

## Build and verify

The current SDKs and dependencies are already installed locally. For a fresh setup,
follow [local-development.md](local-development.md) and resolve the shared package
and four primary apps with `flutter pub get` first.

```powershell
npm run demo:android
npm run demo:test
npm --prefix backend run build
npm --prefix backend test
npm run test:isolation
npm run test:emulators
npm --prefix backend run test:contracts
```

Run `flutter test --no-pub` in the shared Flutter package and each primary app.
The APK build helper fingerprints all maintained Dart source to avoid stale
Windows Gradle output for shared-package changes. Its ignored `manifest.json`
records the source fingerprint and APK SHA-256 checksums.

Optional browser acceptance uses an already installed Playwright and Edge:
build the four primary apps with `flutter build web --no-pub --no-web-resources-cdn`,
then run `node scripts/browser-demo.mjs` from PNG2. It uses the explicit demo
accounts, creates one labelled local test reservation and removes only that
reservation's related records afterward. It blocks non-local data/API requests;
static FlutterFire SDK/font assets are allowed. It does not prove Android device behavior.

## Troubleshooting

- No device: run `adb devices -l`; check the cable, USB mode, debugging and authorization.
- Setup error on launch: start both local services, re-run USB forwarding, then
  fully close/reopen the app. No fallback cloud configuration is used.
- Cannot sign in: use the account matching the app. Read the current local
  credential file; customer registration never creates staff accounts.
- Pricing unavailable: use the explicit demo backend command for this demonstration.
- No eligible resource: ensure the driver is active/on duty, the vehicle is active
  and matches the quote, and neither is locked by another unfinished trip.
- A stale revision/network error requires refresh before another mutation.
- PowerShell/Node test workers may need execution outside a restrictive process sandbox.
- Windows desktop plugin symlinks remain unavailable on this machine. Dependencies
  resolved before that warning; Android/web builds and tests use `--no-pub`.
  A fresh machine should enable its own Flutter prerequisite configuration.

A connected phone and an actual walkthrough are still required before calling the
demo device-verified. Standalone remote demonstrations require a separately
authorized nonproduction hosting/configuration phase.

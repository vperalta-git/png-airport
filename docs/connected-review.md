# AeroTrans Connected: one APK, four authenticated workspaces

Install **Android APKs/aerotrans-all-roles-connected.apk** and open
**AeroTrans Connected**. This is a separate app from **AeroTrans Demo**, the
standalone offline practice APK. Both can remain installed.

Customer, Control Room, Driver and Manager/Supervisor use the existing NestJS API,
Firebase Authentication and shared Firestore booking records. There is no local
practice adapter or fake role login in this connected build. Choosing a workspace
opens sign-in; the backend profile determines the account's actual permissions.

## Current connection requirement

This build connects to the existing isolated **local** backend via USB forwarding.
Keep the review computer running, the services running, and the phone connected.
The Firebase project is demo-aerotrans-png2. It never falls back to production.

**Sending this APK alone does not provide remote access to the backend.** A hosted
nonproduction backend and matching test Firebase configuration are still required
before the supervisor can use the connected version remotely. No hosting,
deployment, public tunnel or production access has been configured. The offline
APK remains available for standalone remote screen/workflow demonstrations.

## Start or reconnect

From PNG2, check existing services first to avoid duplicate processes:

    npm run verify:emulators

The local backend health URL is http://127.0.0.1:8080/api/v1/health.
If stopped, start these in separate terminals and leave them running:

    npm run emulators
    npm run demo:backend

The second command explicitly uses established test-only PGK rates, not approved
commercial tariffs. For a new local environment, prepare managed test accounts:

    npm run demo:setup

Build, validate, forward local ports, install/update, and launch on the phone:

    npm run demo:connected:phone -- -DeviceSerial d381fffa0421

Use the actual serial from adb devices for another phone. Keep it unlocked and
approve any USB debugging / installation prompt. Updating uses adb install -r;
existing application data is preserved. Android 7/API 24 or newer, ARM32/64.

To build/export without installing:

    npm run demo:connected:android

USB reverse ports are backend8080, Auth9099, Firestore8085, Realtime Database9000
and Storage9199. Reapply forwarding after reconnecting USB:

    npm run demo:phone -- --serial d381fffa0421

## Accounts and switching

The account chooser supports all four workspaces. Use the matching local test
account and its generated password from **.local-tools/demo/accounts.json** on
this computer. Staff accounts cannot be created through customer registration.
Keep generated passwords out of commits, reports, screenshots and APK assets;
provide any authorized reviewer credentials separately through an appropriate
private channel. No real credentials or hardcoded test passwords are embedded.

Once signed in, **Switch account** or **Sign out** closes the current workspace
and returns to account selection. The next account must authenticate. Previous
booking pages are discarded so another user cannot inherit them. Selecting the
Supervisor card does not grant supervisor permissions to a customer account.

The current signed-in identity can restore after reopening, provided the backend
and Firebase services are available. If account verification fails, Retry and
Sign out are offered; an unverified profile never opens an operational workspace.

## Review the flow

1. Customer: sign in/register, choose Lae/Nadzab, enter a future PNG pickup time
   and made-up passenger/address details. Request a server quote and book.
2. Switch account to Control Room. Refresh/open that same backend reservation,
   assign an eligible available driver and matching vehicle.
3. Switch to the assigned Driver. Accept with inspection, depart and arrive at
   pickup. The driver can see only assigned work.
4. Switch to the owning Customer and read the booking's pickup code.
5. Switch back to the Driver, verify the code through the API, progress the trip
   and complete it. Completion does not confirm a payment.
6. Switch to Supervisor to review summaries, audit, staff and vehicles.

There are no automatically inserted operational bookings. Lists and summaries
show actual backend records; empty lists are valid. Existing local data is kept.
The explicit setup only provisions its owned demo staff and fleet fixtures.

The UI uses bundled typography, navy/gold controls, responsive forms/dashboards,
separate trip/payment status, real loading/empty/error states and manual refresh
plus background polling. Last successful refresh is shown in PNG time. A failed
refresh preserves prior data with a visible error; it does not report a new result.

## Boundaries

This is an internally signed development review build, not a store release.
PGK amounts use integer minor units; Lae/Nadzab times display in PNG UTC+10.
Established test fares remain PGK100 sedan / PGK150 SUV. They are not commercial
rates; a zero test tax component is not a tax policy. Without explicit test rates
or approved configuration, pricing must remain unconfigured.

No real merchant/payment, GPS movement, SMS, WhatsApp, flight feed or notification
provider is simulated as successful. Payment remains separate from trip status.
Do not enter real operational or personal data into this review environment.

For subsequent changes, rebuild/install with the same phone command. The build
validates native Firebase/Auth/storage registration and the exact connected APK
identity before exporting. The connected native configuration permits HTTP only
to loopback aliases; AppConfig still rejects external API origins. The offline
APK's package, data and lack of network permissions are preserved.

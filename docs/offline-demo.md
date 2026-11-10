# AeroTrans standalone offline APKs

**Superseded delivery:** use the corrected single
**aerotrans-all-roles-offline.apk** described in
[all-roles-offline-demo.md](all-roles-offline-demo.md). The original four-APK
export had missing Android plugin registration and could stop at the reset screen.
The Android build helpers now fix registration, but the older exported binaries
and ZIP are historical and should not be sent to testers.

These four APKs are for testing screens and the four-role workflow without
internet, a computer, USB, Firebase or a hosted backend. They are separate from
the retained online/emulator version.

## Files to send to testers

Use the files in **Android APKs/Offline/**:

- aerotrans-customer-offline.apk
- aerotrans-control-room-offline.apk
- aerotrans-driver-offline.apk
- aerotrans-supervisor-offline.apk
- TESTER-README.txt

The combined archive is **Android APKs/AeroTrans-Offline-Demo-APKs.zip**.
The earlier *-demo.apk files directly in Android APKs/ still require the local
backend. Do not send those as the standalone offline version.

## Install and start

1. Send the APK file(s), or send the ZIP and extract it on the phone.
2. Open an APK on Android. Allow installation from the source app if Android asks.
3. Open the launcher named AeroTrans Customer Offline, Control Room Offline,
   Driver Offline or Supervisor Offline.
4. Tap **Start [role] demo**. No account setup or connection is required.
5. Airplane mode can stay on. The APKs do not have Android's internet permission.

Android 7 / API 24 or newer is required. ARM32 and ARM64 are included.
These are internal demonstration builds, signed for sideloading, not store releases.
The .offline application IDs allow installation alongside the retained .demo apps.

## How the four roles work offline

**Every APK installation has its own practice data. Separate phones and separate
APKs do not share bookings.**

Each APK starts in its named role and includes all four role screens. To test one
booking end to end, stay in ONE APK and use the navy role button at the top to
switch Customer, Control Room, Driver and Supervisor. Return to the dashboard
with Back before changing roles.

There are five starting personas, three vehicles, one unassigned practice
reservation and one assigned driver trip. They are explicitly labelled demo data.
Use the reset control to start again with fresh dates and codes.

## Complete walkthrough

1. Start the Customer demo. Tap Book airport transfer, enter a made-up Lae address
   and passenger details, choose a future PNG pickup time, get the demo quote and
   confirm. Note the OFFLINE-BK reference.
2. On the dashboard, tap the role button and choose **Control Room - Demo Control
   Room**. Open that same reference and assign an available matching vehicle and
   driver. Demo Driver Two / DEMO Sedan Two are initially free for a new sedan trip.
3. Return to the dashboard and switch to **Driver - Demo Driver Two**. Open the
   assigned reservation, complete all four pre-trip checks, accept, depart and
   arrive at the pickup point.
4. Return to the dashboard, switch to Customer, and open that reservation to see
   its pickup code. Note the six digits.
5. Switch back to the assigned driver, open the trip and verify the code.
   Start the transfer, arrive at the destination, then complete it.
6. Payment stays Pending; this demonstration never collects or verifies money.
7. Switch to Supervisor to review summaries, booking activity and audit records.
   Management also supports creating/editing practice staff, setting driver duty,
   and adding/editing vehicles.
8. Reset offline demo clears only this installation's practice data and reloads
   the starting scenarios. It never changes the online backend or other APKs.

## More flow checks

- Cancel a reservation before departure.
- Reassign before departure and confirm the new driver must accept again.
- Try assigning a driver/vehicle already busy with another active trip.
- Try skipping a trip stage; the demo should reject it.
- Enter five incorrect pickup codes to lock the practice code. At the pickup
  stage, the Supervisor can reissue one with a reason.
- Close and reopen the app to check saved practice data and the selected persona.
- Create a practice driver, put that driver on duty, then assign work.
- Mark an unused vehicle as Maintenance and confirm it is unavailable for dispatch.

Codes last 24 hours in this practice mode. If returning later, reset the demo or
reissue the code as Supervisor at the pickup stage.

## Optional practice sign-in / registration

The startup screen also offers a local sign-in/registration walkthrough.
All starting practice accounts use **DemoOnly2026!**:

| Persona | Email |
| --- | --- |
| Customer | customer@offline.aerotrans.invalid |
| Control Room | control@offline.aerotrans.invalid |
| Driver | driver@offline.aerotrans.invalid |
| Second driver | driver2@offline.aerotrans.invalid |
| Supervisor | supervisor@offline.aerotrans.invalid |

Use made-up details and a made-up password. These accounts and the role switcher
are local simulations, not real Firebase authentication or a security boundary.

## Scope of this demo

Local JSON snapshots retain reservations, quotations, personas, vehicles, pickup
codes, attempts, activity and audits through SharedPreferences. Data never uploads.
Clear app storage/uninstalling removes that app's data. This storage is for practice
only; the retained NestJS/Firebase implementation remains the operational design.

The demo uses the established test fares of PGK 100.00 for a sedan and PGK 150.00
for an SUV. They are not operator-approved rates. A zero test tax component is not
a tax policy. PNG pickup times display in UTC+10 for the Lae / Nadzab pilot.

There is no real payment, GPS movement, flight feed, messaging, notification,
security-escort dispatch or offline-to-online synchronization. This demonstrates
the implemented core role flows; it does not validate live backend security or
provider integrations.

## Rebuild / retain the online version

From PNG2:

    npm run demo:offline:android

This builds the separate lib/main_offline.dart entrypoints with the explicit
AEROTRANS_OFFLINE_DEMO=true flag. The build script checks package IDs, signatures,
absence of network permissions and absence of Firebase auto-initialization before
copying the APKs into the delivery folder. The manifest records source/checksums.

The retained online entrypoints are still lib/main.dart:

    npm run demo:android

They keep their .demo IDs, emulator/backend configuration and normal online
authentication. The offline flag defaults to false. No NestJS backend was replaced.

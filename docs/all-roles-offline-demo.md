# AeroTrans: one offline APK, all four roles

Install **aerotrans-all-roles-offline.apk** and open **AeroTrans Demo**.
Choose Customer, Control Room, Driver or Manager / Supervisor. All roles use the
same saved practice records inside this one app. No internet, USB connection,
Firebase project or backend is needed after installation.

Android 7/API 24 or newer is required. ARM32 and ARM64 are included. This is an
internal sideloaded demonstration build, not a store or production release.

## Switch accounts

On a role dashboard, tap the navy role button at the top. Choose another account
to continue the same booking. Return from booking details to the dashboard with
Back before switching. The second demo driver is also in this account chooser.
Sign out to return to the four-role starting screen.

Each phone keeps its own local practice data. Different phones and the older
separate APKs do not synchronize or share these records.

## Test one complete booking

1. Choose Customer. Book an airport transfer with made-up details, a future PNG
   pickup time and a demo quote. Note the OFFLINE-BK reference.
2. Return to the dashboard and switch to Control Room. Open that same reference.
   Assign a matching available driver and vehicle. For a new sedan trip, Demo
   Driver Two and DEMO Sedan Two are initially free.
3. Switch to Driver - Demo Driver Two. Open that booking, complete all four
   pre-trip checks, accept, depart and arrive at pickup.
4. Switch to Customer and read that booking's six-digit pickup code.
5. Switch to the assigned driver, verify the code, start the trip, arrive at the
   destination and complete the transfer.
6. Switch to Supervisor to review activity, audit records, staff and vehicles.
7. Close and reopen the app: the selected account and practice data should remain.

There are two explicit starting practice bookings and three demo vehicles. The
primary driver already has an assigned example trip. Use the second driver for
a new booking, or complete/cancel the earlier trip first. Driver acceptance,
inspection, pickup codes, trip stages and resource conflicts are checked locally.

Payment remains Pending. The demo does not collect, confirm or verify money.
It uses established test-only fares: PGK 100.00 sedan and PGK 150.00 SUV. These
are not approved commercial tariffs; zero test tax is not a business tax policy.
Lae / Nadzab pickup times display in PNG UTC+10.

## Reset and practice sign-in

The reset icon asks before clearing only this installation's practice data. It
recreates fresh scenarios and returns to the role chooser. Online/backend data
and older applications are unaffected. Pickup codes last 24 hours in practice
mode; reset or use Supervisor reissue at pickup if a code expires.

Optional local sign-in / customer registration is also available. Starting
practice accounts all use **DemoOnly2026!**:

- customer@offline.aerotrans.invalid
- control@offline.aerotrans.invalid
- driver@offline.aerotrans.invalid
- driver2@offline.aerotrans.invalid
- supervisor@offline.aerotrans.invalid

Use only made-up personal details and passwords. Accounts and unrestricted demo
role selection are simulations, not real authentication or server authorization.
There are no real payments, GPS feeds, messages, provider notifications or data
uploads. The existing NestJS/Firebase implementation is retained separately.

## Development and direct phone updates

From PNG2, build/export the APK:

    npm run demo:all-roles:android

Build, update the connected phone and launch the combined app:

    npm run demo:all-roles:phone -- -DeviceSerial d381fffa0421

Use the actual serial from adb devices when connecting another phone. Keep the
phone unlocked and approve USB debugging/installation prompts if requested.
Updating with adb install -r preserves this app's practice data. No app is
automatically uninstalled. The older online and separate offline apps can coexist.

The build prepares native Android plugins before compilation and checks that the
actual APK contains the generated plugin registrant and storage plugin. It also
checks identity, signature and absence of network permission/Firebase automatic
initialization. A startup storage failure shows Retry and a recoverable reset
error; a missing plugin explicitly requires a corrected APK instead of a reset loop.

# AeroTrans Connected - online Android test APK

Install `Android APKs/aerotrans-all-roles-online.apk` and open **AeroTrans Connected**.
Version 1.2.0, build 4. One app contains Customer, Control Room, Driver and Supervisor,
with separate Arrivals and Departures sections. The backend determines permissions.

This build uses the existing hosted NestJS API and the separately approved Firebase
test project `aerotrans-png-test-7d7128`. Internet access is required. The review
computer, USB connection and local emulators are not required for normal use.
The live project `airport-png-c866b` is not used or changed.

Use the same test accounts as the website. Their private login sheet is under
ignored `.local-tools/hosted-test/TEST_ACCESS.txt`; send it privately to testers.
Customer registration creates a real test passenger account. Selecting a role card
does not grant access to that role.

## Workflows

- Arrivals: airport pickup, backend passenger OTP, transfer to the Lae address.
- Departures: Lae customer pickup, backend passenger OTP, airport drop-off.
- Control Room assigns available drivers and vehicles. Drivers accept inspection
  before travel. Shared locks prevent double booking across the two queues.
- Supervisor reviews operations, staff, fleet and audit records.
- All prices are labelled test rates. Completing a trip never verifies payment.

## Build and install

Native public SDK settings are generated from the registered Android test app and
kept in ignored `.local-tools/hosted-test/firebase-android.json`. No Admin key or
test account password belongs in the APK. Backend identity is checked before
Firebase initializes; this build permits HTTPS only, with no cleartext exceptions.
For a fresh checkout, download the **Android** google-services.json for package
`com.pngtransfer.png_transfer_client.connected` from the **test** project's settings
and save it at that ignored path. The builder validates project, package and native
app ID and generates only the allowed public Dart defines. Do not use a web SDK
app ID or download a service-account key for this step.

From PNG2:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-android-connected.ps1 -Hosted
# Build and install when exactly one unlocked/authorized phone is connected:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-android-connected.ps1 -Hosted -Install
```

Equivalent shortcuts are `npm run demo:online:android` and
`npm run demo:online:phone`.

The hosted build retains the connected package ID, so it can update the previous
local connected app with the same test signing key. It does not replace **AeroTrans
Demo** or clear its practice data. Original local APK files remain available, but
use the new **online** file for remote testing. The existing no-Hosted build command
still produces the local/USB connected variant.

This APK uses the existing development signing key for sideloaded testing. Store
release signing, payment providers, tracking, notifications and commercial rates
remain separate work. Refer to the Android update report for actual build/device
verification; installation or physical-device tests are never implied by a build.

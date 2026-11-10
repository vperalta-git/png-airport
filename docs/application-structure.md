# Maintained Flutter applications

Current Android demonstration: these same four primary folders build separate
APK packages with a .demo suffix. Their main() entrypoints call runMobileDemo with
the canonical role. Shared mobile_demo_app.dart, mobile_demo_booking.dart and
mobile_demo_management.dart use the v1 API and existing AviationTheme. Legacy
screens/BLoCs remain in source, and duplicate apps retain the foundation gate.
See android-demo.md for installation. The Batch A comparison below is historical.

Primary entrypoints:

| Role | App | Native Android applicationId |
| --- | --- | --- |
| Customer / Passenger | apps/passenger_web | com.pngtransfer.png_transfer_client |
| Control Room / Dispatcher | apps/control_room_web | com.pngtransfer.png_transfer_control_room |
| Driver | apps/driver_mobile | com.pngtransfer.png_transfer_driver |
| Manager / Supervisor | apps/admin_web | com.pngtransfer.png_transfer_supervisor |

Preserve AviationTheme, design tokens, BLoCs, widgets and screens. Share new
configuration, versioned DTOs and HTTP handling in png_transfer_flutter_core.
Do not implement four separate backend contracts.

## Duplicate review at checkpoint d651123

scripts/compare-apps.mjs compared every app file except generated/cache/ephemeral
directories, including Android, iOS, Windows, macOS, Linux, web and pubspec files.

| Pair | Files compared | Actual baseline differences |
| --- | --- | --- |
| client_flutter / passenger_web | 160 / 160 | login_screen.dart, profile_screen.dart |
| control_room_flutter / control_room_web | 155 / 155 | trailing blank line in the Firestore service |
| driver_flutter / driver_mobile | 153 / 152 | driver_flutter/devtools_options.yaml only |
| supervisor_flutter / admin_web | 151 / 152 | admin_web/devtools_options.yaml only |

No native source/config difference was found within each pair at that checkpoint.
This does not prove the apps were tested on those platforms or authorize deletion.
All folders are retained. The later team should decide whether to consolidate
duplicate entrypoints after native release requirements and usage are confirmed.

Batch A applies the common local-only startup to all 11 apps, including the
corporate/operator/security expansion apps, so a secondary entrypoint cannot
silently initialize the old cloud project. Existing Firebase option/native JSON
files now use demo-only identifiers. Debug Android manifests permit local HTTP;
release settings are not loosened.

Only the four primary app dependency/test/build paths are verified in Batch A.
Their lockfiles and smoke tests consequently differ from untouched duplicate
test/lock paths. Re-run npm run check:apps to inspect current differences; the table
above records the initial review, not a promise of continued byte identity.

# PNG2 website: source, build and hosting

The website source is included in https://github.com/vperalta-git/png-airport.
The project is Flutter Web with a NestJS/Firebase backend.

Hosted-test update, 10 November 2026: an isolated Firebase test project and separate
Vercel API project now exist. Runtime support is implemented, but authentication
activation, dedicated credential approval and deployment acceptance are pending.
See [hosted-test.md](hosted-test.md) for the current setup and safety boundaries.
The website remains a preview until that setup is verified.

| Purpose | Repository path |
| --- | --- |
| Primary Flutter website project | apps/passenger_web |
| Unified four-role website entrypoint | apps/passenger_web/lib/main_connected.dart |
| Browser HTML loader and web manifest | apps/passenger_web/web |
| Shared screens, design and API contracts | packages/png_transfer_flutter_core |
| NestJS backend | backend |
| Generated folder to host after building | apps/passenger_web/build/web |
| Separate Control Room web entrypoint | apps/control_room_web |
| Separate Manager/Supervisor web entrypoint | apps/admin_web |

Use the unified entrypoint for one website containing all four account flows.
Workspace choices open real sign-in; backend permissions determine which account
workspace opens. They do not grant access by selecting a role.

## Vercel import settings

Import vperalta-git/png-airport with these settings:

| Setting | Value |
| --- | --- |
| Root Directory | Repository root (`.`), not backend |
| Framework Preset | Other |
| Install Command | Use the repository's vercel.json value |
| Build Command | bash scripts/vercel-build-web.sh |
| Output Directory | apps/passenger_web/build/web |

Root vercel.json configures a static Flutter build and SPA routing. The build
script obtains the pinned Flutter 3.35.4 SDK, resolves Flutter dependencies, and
builds the correct four-role entrypoint. It does not start or deploy NestJS.

If the existing Vercel project was imported as backend, change Root Directory to
the repository root in Project Settings, select Other as the framework, and remove
the old NestJS/Node build overrides before redeploying the latest main commit.
Changing vercel.json cannot change the project's dashboard Root Directory setting.
Keep the full monorepo available so Flutter can find packages/png_transfer_flutter_core.

The screenshot's No entrypoint found error comes from a Node/NestJS build attempt,
not Flutter website compilation. The API source does contain backend/src/main.ts;
adding a second Node entrypoint is not the website fix. npm deprecation warnings
are separate from that fatal detection error.

This configuration addresses frontend build selection and packaging. The hosted
backend limitation below still applies: a successfully hosted frontend alone
cannot authenticate or load operational data with the current local-only runtime.

Verification: Bash syntax and JSON checks passed. The complete build script ran
successfully with the installed pinned Flutter SDK and generated build/web in
38 seconds. The cold SDK download and an actual Vercel deployment were not run
from this workspace; the dashboard root/framework settings must still be corrected.

## Build the website

Install a compatible Flutter SDK and resolve dependencies in apps/passenger_web:

```sh
cd apps/passenger_web
flutter pub get
flutter build web --target lib/main_connected.dart --dart-define=AEROTRANS_CONNECTED_REVIEW=true --no-web-resources-cdn
```

The output directory is **apps/passenger_web/build/web**, relative to the repository
root. A static host serves that generated directory, not lib/ or the web/ loader
templates. Build output is intentionally ignored by Git. The connected website
compiled successfully with Flutter 3.35.4 during verification.

The build environment must have Flutter installed. This repository is not a
React/Next.js application, so a hosting service's default npm build is insufficient.
For subdirectory hosting, configure the matching Flutter --base-href value when
building. Use an SPA fallback to index.html for application routes.

## Current backend limitation before public use

The current build is an isolated local review application. Its configuration
accepts only loopback backend/emulator hosts and intentionally refuses cloud
fallback. Public hosts display the AeroTrans website with a clear service-setup
notice and unavailable sign-in. They do not probe the visitor's localhost or
initialize Firebase with local settings. Uploading these files does not create
a working remote backend or activate bookings.

The website startup is separate from the phone connection screen, so hosted
visitors are not shown USB/APK instructions. When running locally with verified
services, the existing authenticated four-role application remains available.

Public-startup verification: 14 focused session/startup tests passed, Flutter
analysis found no issues, and the corrected release website compiled. Browser
checks at 1440px and 390px on a virtual public HTTPS origin rendered the landing
page with zero API/Firebase/localhost requests, disabled sign-in and safe retry.
This is not a claim that hosted authentication or a Vercel deployment was tested.

For a public, functional website the next deployment work must provide:

- A nonproduction Firebase project with appropriate Auth domains and secure rules.
- A hosted HTTPS NestJS backend using that same project's data and identity.
- An explicit hosted frontend/backend configuration mode and matching CORS origins.
- The selected hosting site's actual domain and build/deployment settings.

Root firebase.json is currently emulator configuration. The historical hosting
example under infrastructure requires confirmed site/service settings and is not
an active deployment. No hosting or backend deployment was performed by the source
push. Production credentials, private keys and local account passwords stay out
of the repository and frontend build.

## Run the connected website locally

Follow connected-review.md to start the existing emulators and backend. Then, from
apps/passenger_web:

```sh
flutter run -d chrome --target lib/main_connected.dart --dart-define=AEROTRANS_CONNECTED_REVIEW=true --web-port=5001
```

This uses the same server-generated quotes, reservations, dispatch, driver OTP and
supervisor management as the connected app. See
[connected-review.md](connected-review.md) for the walkthrough and current limits.

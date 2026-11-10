# PNG2 source publication

Requested destination: https://github.com/vperalta-git/png-airport.
Prepared: 10 November 2026.

This publication contains the current PNG2 source: Flutter web/mobile apps, shared
packages/contracts, NestJS backend, configuration examples, tests and handoff docs.
The unified connected website compiles successfully from
apps/passenger_web/lib/main_connected.dart.

The destination was empty. A clean current-source snapshot is used instead of
transferring the original repository's legacy history. That older history contains
hardcoded registered-account/contact records that could not be verified as test
data. The original working copy, branch, index, origin and history are preserved
locally; no history rewrite or force push is needed.

The publication checkout is kept locally under ignored
.local-tools/publication/. It has its own Git history and the new repository as
origin. Future updates from the original workspace must continue using reviewed
current-source snapshots; do not merge or push the legacy parent history into
the new repository. A fresh clone of the new repository can be developed and
pushed normally.

Private environment files, generated local accounts/passwords, emulator snapshots,
APKs, SDK/build output and dependency directories are excluded. The current source
scan found no actual private keys, provider tokens or operational credential
records. The clearly labeled offline practice password is public demo fixture data.

Verification for this source state:

- Unified connected Flutter website: compilation passed.
- Shared Flutter regression suite: 45 passed; 5 offline-only tests skipped normally.
- Separate offline UI preservation checks: 5 passed.
- Backend verification: 8 suites / 22 tests passed, including a real-emulator
  four-role workflow.
- Connected Android APK: compiled and exported with package/security checks.
  Connected-phone installation and native acceptance are still pending; no phone
  was detected on 10 November.

This is a source push, not a website/backend deployment. The connected runtime
currently requires local services. Remote supervisor reviews still need hosted
nonproduction services and matching Firebase configuration. No deployment or
production data change is included.

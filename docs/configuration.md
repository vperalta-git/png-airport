# Local configuration

The authoritative Batch A setup is [local-development.md](local-development.md).
Copy only the safe root .env.example when direct backend configuration is needed.

The active Firebase project is demo-aerotrans-png2. Both Firebase config files
bind Auth, Firestore, RTDB and Storage to loopback. Root npm runners populate and
validate required emulator environment variables; the backend refuses missing
endpoints, conflicting project/bucket/database overrides and service credentials.

Flutter uses the shared AppConfig/LocalFirebase bootstrap. API_BASE_URL must be
a local HTTP origin. EMULATOR_HOST is 127.0.0.1 (web/desktop) or 10.0.2.2 (Android
emulator). The primary web ports 5001-5004 have explicit local CORS permissions.
Initialization errors display a blocking setup state.

No production project, private key, worker secret, webhook secret, route price,
tax assumption or live flight/provider setting is configured by this batch.
Cloud startup is deliberately unavailable. Configure future environments only
after Batch B security and business integration, with separate approval for
deployment. Real .env files and credential files must stay out of Git.

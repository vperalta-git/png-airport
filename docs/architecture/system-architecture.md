# Papua New Guinea Airport Transfer, Armed Escort & Control Room Platform
## Enterprise System Architecture Specification (Firebase + Google Cloud Run + Flutter)

### 1. Architectural Philosophy
The platform delivers high-security, resilient ground transportation and armed escort coordination tailored for Papua New Guinea operational conditions (specifically the pilot location in Lae, Morobe Province connecting Nadzab / Tomodachi International Airport [AYNZ] with the industrial port city of Lae along the Highlands Highway).

```mermaid
graph TD
    subgraph Client Tier [Flutter Multi-Platform]
        PW[Passenger Web - Flutter Web]
        CRW[Control Room Desk - Flutter Web]
        AW[Admin Portal - Flutter Web]
        OW[Partner Operator Portal - Flutter Web]
        CW[Corporate Travel Desk - Flutter Web]
        DM[Driver App - Android / iOS Offline-First]
        SM[Security Escort App - Android / iOS]
    end

    subgraph Edge & Distribution [Firebase Hosting & CDN]
        FH[Firebase Hosting Multi-Site]
        PW --> FH
        CRW --> FH
        AW --> FH
        OW --> FH
        CW --> FH
    end

    subgraph Application & Compute Tier [Google Cloud Run]
        CR[Cloud Run NestJS Backend /api/v1]
        FH -->|Rewrites /api/**| CR
        DM -->|HTTPS / Dio + Bearer Token| CR
        SM -->|HTTPS / Dio + Bearer Token| CR
    end

    subgraph Data & Persistence Tier [Google Cloud / Firebase]
        FS[(Cloud Firestore - Operational System of Record)]
        RTDB[(Firebase Realtime Database - Live GPS & Telemetry)]
        CS[(Cloud Storage - Permits, Licenses, e-POD Signatures)]
        FA[Firebase Authentication - Identity Tokens & RBAC]
    end

    subgraph Orchestration & Workers [Google Cloud Engine]
        CT[Cloud Tasks - Delay Recalculation & Timeouts]
        CSched[Cloud Scheduler - Daily Compliance Sweeps]
        PS[Cloud Pub/Sub - Event Bus & SOS Alerts]
    end

    CR --> FS
    CR --> RTDB
    CR --> CS
    CR --> FA
    CR --> CT
    CSched --> CR
    CR --> PS
```

---

### 2. Division of Responsibility & Data Ownership

| Subsystem | Technology | Authoritative Responsibility |
| :--- | :--- | :--- |
| **Identity & Authentication** | Firebase Authentication | User identity, email/phone OTP, session revocation, and verified ID tokens. |
| **Operational System of Record** | Cloud Firestore | Bookings, resource master data, atomic reservation holds, quotations, dispatches, compliance audits, invoices, and immutable event logs. |
| **Live Telemetry & Signals** | Firebase Realtime Database | Sub-second active vehicle GPS coordinates, driver online presence, and zero-latency P1 emergency SOS broadcasts. |
| **Document & Evidence Vault** | Cloud Storage for Firebase | Driver licenses, vehicle roadworthiness certificates, firearm permits, incident scene photos, and e-POD signature captures. |
| **Trusted Business Logic** | Google Cloud Run (NestJS) | Dynamic pricing with 10% PNG GST, atomic double-booking prevention, dispatch compliance verification, flight radar polling, webhook signature verification, and 80/20 partner settlements. |
| **Async Tasks & Jobs** | Cloud Tasks & Scheduler | Scheduled flight monitoring, 10-minute driver acknowledgment timeouts, and daily 06:00 AM compliance sweeps. |

---

### 3. Pilot Deployment: Lae, Morobe Province

- **Airport**: Nadzab Tomodachi International Airport (AYNZ / LAE).
- **Corridor**: 42.5 km along the Markham Valley / Highlands Highway.
- **Base Command**: Nadzab Airport Base Command & Depot (`branch_nadzab_lae`).
- **Standard Threat Levels**:
  - `Level 1 - Low`: Standard daytime transfer (Sedan or SUV).
  - `Level 2 - Elevated`: Night transfers (20:00 - 06:00) requiring onboard security officer.
  - `Level 3 - High Risk`: Armed chase car (Toyota LandCruiser 79 with licensed RPNGC private security detail) for corporate minerals/banking delegations.
  - `Level 4 - Tactical Convoy`: Armored B6 Prado + Lead LandCruiser + Tactical Close Protection Officers.


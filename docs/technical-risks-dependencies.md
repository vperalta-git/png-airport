# Technical Risks, Mitigations & Third-Party Dependencies

### 1. PNG Operational Environment Risks & Mitigations

| Risk | Impact | Architectural Mitigation Strategy |
| :--- | :--- | :--- |
| **Intermittent / Absent 3G/4G Mobile Coverage** | High | **Offline-First Architecture**: Driver and security apps operate locally using SQLite/AsyncStorage with an idempotent monotonic queue. Actions succeed locally and sync silently when network connectivity returns. |
| **Highway Security Risks (e.g., Markham Valley, Highlands Highway)** | Critical | **Security Personnel Tracking & Escort Rules**: Mandatory armed escort flag for designated high-risk zones/times; one-touch SOS with offline location caching; geofence exit alerts. |
| **External Aviation API Outages (Flightradar24 / Airline APIs)** | High | **Flight Provider Abstraction**: Dedicated fallback mode allowing manual control room entry of flight ETAs; local 90s caching; multi-provider failover. |
| **Power Outages & Unreliable Local Telematics Hardware** | Medium | **Dual-Stream Tracking**: Support both dedicated in-vehicle GPS hardware and driver smartphone GPS breadcrumbs with automatic source fallback. |
| **Data Corruption from Concurrent State Changes** | Medium | **Cloud Run & Firebase Optimistic Locking & Audit Events**: Version-tracked operational events with server-side validation preventing race conditions during resource assignment. |

---

### 2. Third-Party Dependencies Matrix

| Category | Primary Service / Library | Fallback / Alternative | Strategy |
| :--- | :--- | :--- | :--- |
| **Aviation Intelligence** | Flightradar24 API | AviationStack / Manual Control Desk | Abstract `FlightProvider` class |
| **Mapping & Routing** | OpenStreetMap / Leaflet / Mapbox | Google Maps / Local GeoJSON cache | Abstract GIS interface |
| **Mobile Runtime** | Expo SDK / React Native | React Native CLI native builds | Expo Managed workflow |
| **SMS Gateway** | Twilio / Digicel PNG SMS API | Console / Email fallback | Abstract Notification interface |
| **Telematics / GPS** | Traccar / Teltonika Fleet API | Mobile Smartphone GPS | Abstract Telematics interface |
| **Payments** | Bank South Pacific (BSP) / Mobile Money | Corporate PO / Cash / Cloud Run & Firebase Invoice | Abstract Payment Gateway |

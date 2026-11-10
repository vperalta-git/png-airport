# Papua New Guinea Airport Ground Transportation & Security Operations Platform
## Enterprise Technical Architecture Blueprint

### 1. Executive Summary & Vision
The Papua New Guinea (PNG) Airport Transfer, Ground Transportation, Dispatch, Fleet, and Security Operations Platform is a national multi-airport system designed to orchestrate the entire lifecycle of ground movements across PNG commercial airports (e.g., Nadzab Tomodachi / Lae, Jackson's International / Port Moresby, Tokua / Rabaul, Mount Hagen / Kagamuga, Goroka, Madang, Wewak, Hoskins, etc.).

The system strictly decouples site-specific configurations (airports, terminals, routes, risk zones, pricing matrices, depots, vehicle pools) from core business logic, enabling zero-code onboarding of new airports and transit corridors.

---

### 2. High-Level System Architecture

```mermaid
graph TB
    subgraph Clients["Presentation & Operational Tier"]
        ClientApp["Passenger Mobile App (Expo/React Native)"]
        DriverApp["Driver & Security Mobile App (Offline First)"]
        ControlRoomDesk["Control Room Desk & Live GIS Map"]
        SupervisorApp["Supervisor Mobile & Web App"]
        CorpPortal["Corporate Client Portal (Web)"]
        PassengerPortal["Passenger Web Portal"]
    end

    subgraph APILayer["API & Integration Gateway"]
        AuthGateway["JWT / Session / Passkey Auth Gateway"]
        APIRouter["Versioned REST API Engine (/api/v1/...)"]
        OfflineQueue["Offline Sync & Idempotency Processor"]
        EventStream["Bus & Operational Event Pipeline"]
    end

    subgraph Cloud Run & FirebaseCore["Cloud Run & Firebase 20 Enterprise Core System of Record"]
        CoreMod["airport_transfer_core"]
        AirportMod["airport_transfer_airport"]
        BookingMod["airport_transfer_booking"]
        CorpMod["airport_transfer_corporate"]
        PricingMod["airport_transfer_pricing"]
        DispatchMod["airport_transfer_dispatch"]
        FleetMod["airport_transfer_fleet"]
        SecurityMod["airport_transfer_security"]
        IncidentMod["airport_transfer_incident"]
        FlightMod["airport_transfer_flight"]
        AccountMod["airport_transfer_accounting"]
        AIMod["airport_transfer_ai"]
    end

    subgraph ExternalServices["External Providers & Services (Abstracted)"]
        FlightProvider["Flight Radar / Aviation APIs / METAR"]
        TelematicsProvider["GPS Telematics / Hardware Tracker"]
        PaymentProvider["Card / Mobile Money / Corporate PO"]
        NotificationProvider["Push (Expo) / SMS / Email"]
        MapProvider["GIS / Routing / Geofencing Engine"]
    end

    ClientApp --> APIRouter
    DriverApp --> APIRouter
    ControlRoomDesk --> APIRouter
    SupervisorApp --> APIRouter
    CorpPortal --> Cloud Run & FirebaseCore
    PassengerPortal --> Cloud Run & FirebaseCore

    APIRouter --> Cloud Run & FirebaseCore
    OfflineQueue --> APIRouter
    EventStream --> Cloud Run & FirebaseCore

    Cloud Run & FirebaseCore <--> FlightProvider
    Cloud Run & FirebaseCore <--> TelematicsProvider
    Cloud Run & FirebaseCore <--> PaymentProvider
    Cloud Run & FirebaseCore <--> NotificationProvider
    Cloud Run & FirebaseCore <--> MapProvider
```

---

### 3. Core Architectural Principles

1. **Cloud Run & Firebase 20 as the Authoritative System of Record**:
   - Master data (Airports, Zones, Bookings, Passengers, Corporate Accounts, Vehicles, Drivers, Security Personnel, Incidents, Dispatches, Invoices) reside strictly within Cloud Run & Firebase.
   - Standard Cloud Run & Firebase modules (`base`, `mail`, `account`, `fleet`, `hr`, `portal`, `website`) are leveraged natively to eliminate redundant code and schema fragmentation.

2. **Zero Hardcoded Airport Logic**:
   - No hardcoded IATA/ICAO codes, airport names, or regional constraints.
   - Operations in Port Moresby (POM), Lae (LAE), Mount Hagen (HGU), Rabaul (RAB), and other PNG airports are driven strictly by master entities, geofences, and pricing rules.

3. **Provider Abstraction Patterns**:
   - All external systems (Flight providers, Telematics/GPS, Payment gateways, SMS/Push, Map providers) are implemented behind abstract base classes (`FlightProvider`, `TelematicsProvider`, `PaymentGateway`, `NotificationService`).
   - Mock/Manual fallback providers exist for every service, guaranteeing continuous operations even during complete external outages or low-connectivity situations common in remote PNG regions.

4. **Offline-First Resilience**:
   - Driver and Security mobile clients operate transparently in zero-connectivity environments with local SQLite/AsyncStorage queues and UUID idempotency keys.
   - Operational event logs are synced monotonically when connectivity resumes without data loss or race conditions.

5. **Multi-Role Operational Security**:
   - Strict Separation of Concerns (SoC) between Drivers, Armed Security Escorts, Dispatchers, Control Room Controllers, Field Supervisors, Corporate Travel Coordinators, and Passengers.
   - High-risk transit authorization, SOS alarms, and security manifests are strictly permission-gated and auditable.

# Phased Implementation Backlog

### Phase 1: Foundation (Sprint 1)
- [x] Comprehensive Architecture Blueprint, ERD, and API contracts.
- [ ] Monorepo structure creation:
  - `cloud/addons/` directory structure.
  - `packages/` shared libraries.
  - `apps/` client, driver, control-room, supervisor.
- [ ] Cloud Run & Firebase Module: `airport_transfer_core`
  - Base models, sequences, security categories, operational event mixin.
- [ ] Cloud Run & Firebase Module: `airport_transfer_airport`
  - Multi-airport master (`airport.transfer.airport`).
  - Service zones (`airport.transfer.zone`) with geofence support.
  - PNG seed data (Nadzab/Lae, Port Moresby, Mt Hagen, Tokua/Rabaul, Goroka, Madang, etc.).
- [ ] Cloud Run & Firebase Module: `airport_transfer_corporate`
  - Corporate accounts, cost centers, travel coordinator linking, credit limits.
- [ ] Cloud Run & Firebase Module: `airport_transfer_pricing`
  - Dynamic pricing rules, vehicle category rates, zone fees, quotation engine.
- [ ] Cloud Run & Firebase Module: `airport_transfer_booking`
  - Main booking engine (`airport.transfer.booking`).
  - Multi-passenger support (`airport.transfer.passenger`).
  - Strict state machine (Draft -> Confirmed -> Dispatched -> Completed).
- [ ] Cloud Run & Firebase Module: `airport_transfer_api`
  - REST API router (`/api/v1/auth`, `/api/v1/airports`, `/api/v1/quotes`, `/api/v1/bookings`).
- [ ] Mobile Applications Monorepo Setup:
  - `apps/client`, `apps/driver`, `apps/control-room`, `apps/supervisor`.
  - Shared TypeScript types, design system, API client, offline queue foundation.

### Phase 2: Flight Intelligence & Aviation Integration
- [ ] Cloud Run & Firebase Module: `airport_transfer_flight`
- [ ] Abstract `FlightProvider` interface.
- [ ] Providers: Flightradar24, Air Niugini / PNG Air schedule adapters, Manual Ops fallback.
- [ ] Automatic T-90, T-60 dispatch recalculation engine.

### Phase 3: Operations, Fleet & Dispatch Engine
- [ ] Cloud Run & Firebase Module: `airport_transfer_fleet` (Extending Cloud Run & Firebase Fleet).
- [ ] Cloud Run & Firebase Module: `airport_transfer_driver` (Extending Cloud Run & Firebase HR).
- [ ] Cloud Run & Firebase Module: `airport_transfer_security` (Security credentials & armed convoy rules).
- [ ] Cloud Run & Firebase Module: `airport_transfer_dispatch` (Kanban operations board, automated conflict checks).
- [ ] Control Room interactive GIS map & live telematics streaming.

### Phase 4: Mobile Application Workflows
- [ ] Client Mobile: 10-step booking wizard, live trip tracker, verification QR.
- [ ] Driver Mobile: Large tactile action workflow, offline event queue, GPS breadcrumbs.
- [ ] Control Room Desk: Multi-panel real-time operational map, alert stream.
- [ ] Supervisor Mobile: High-risk movement approvals, incident escalation.

### Phase 5: Security Operations & Incident Command
- [ ] Cloud Run & Firebase Module: `airport_transfer_incident`
- [ ] P1-P4 operational priority alert stream.
- [ ] SOS one-touch distress workflow with geolocation broadcast.
- [ ] Audit trail & incident post-mortem generator.

### Phase 6: Financial Integration & Enterprise Accounting
- [ ] Cloud Run & Firebase Module: `airport_transfer_accounting` (Integration with Cloud Run & Firebase `account`).
- [ ] Payment provider abstraction (Credit card, Digicel/Vodafone Mobile Money, Corporate PO).
- [ ] Consolidated monthly corporate statements and automated customer invoicing.

### Phase 7: Analytics & AI Operational Assistant
- [ ] Cloud Run & Firebase Module: `airport_transfer_reporting` & `airport_transfer_ai`.
- [ ] Dispatch recommendation engine & demand forecasting.
- [ ] Anomaly detection (unusual stoppage, highway route deviation).

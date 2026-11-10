# PNG Secure Airport Ground Transportation — Flutter Applications Suite

This directory contains the enterprise applications built on Flutter (Web, Android, and iOS) sharing common design tokens and domain models from `packages/png_transfer_flutter_core`.

## Application Matrix

| # | Application | Mobile / Cross-Platform Directory | Web Directory | Target Platform | Primary Role |
|---|---|---|---|---|---|
| 1 | **Passenger Booking** | `client_flutter` | `passenger_web` | Flutter Web, Android & iOS | Passengers & Travel Bookers |
| 2 | **Control Room Operations** | `control_room_flutter` | `control_room_web` | Flutter Web, Desktop & Tablet | Dispatchers & Airspace Operators |
| 3 | **Executive Administration** | `supervisor_flutter` | `admin_web` | Flutter Web, Desktop & Tablet | Company Supervisors & System Admins |
| 4 | **Partner Operator Portal** | — | `operator_web` | Flutter Web | 3rd-Party Transport Operators |
| 5 | **Driver Mobile Terminal** | `driver_flutter` / `driver_mobile` | — | Flutter Android & iOS | Commercial Chauffeurs & Transport Drivers |
| 6 | **Tactical Security Escort** | `security_mobile` | — | Flutter Android & iOS | Armed Close Protection Officers (RPNGC) |
| 7 | **Corporate Client Portal** | — | `corporate_web` | Flutter Web | Mining, Energy & Corporate Procurement Desks |

## Common Architecture

- **State Management:** BLoC / Riverpod
- **Theme & Design System:** `AviationTheme` (Executive Light & Tactical Dark) in `packages/png_transfer_flutter_core`
- **Backend API:** Google Cloud Run NestJS backend (`https://png-transfer-backend-cbsgoiuwbq-as.a.run.app`)
- **Real-Time Database:** Cloud Firestore operational collections and Firebase Realtime Database GPS coordinates (`airport-png`)
- **Security Protocols:** SHA-256 QR boarding passes, 6-digit offline verification OTPs, and one-touch P1 emergency SOS
- **Offline Capability:** Idempotent client-side queue with offline sync and collision deduplication

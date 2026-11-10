> Historical prototype specification. The authoritative Batch A wire contract is
> [contracts-v1.md](contracts-v1.md) and packages/types/src/v1.ts / requests.ts.
> Numeric/snake_case examples below are retained design history, not an active
> competing API contract. Operational routes remain unavailable pending Batch B.

# REST API Contracts & Response Specifications

### 1. Standard Protocol & Response Wrapper
All REST API endpoints are served under `/api/v1/` and enforce JSON serialization. Every response conforms to the strict envelope pattern:

```json
// Success Response
{
  "success": true,
  "data": {},
  "meta": {
    "timestamp": "2026-10-07T00:00:00Z",
    "request_id": "req-98f23a1c"
  },
  "error": null
}

// Error Response
{
  "success": false,
  "data": null,
  "meta": {
    "timestamp": "2026-10-07T00:00:00Z",
    "request_id": "req-98f23a1c"
  },
  "error": {
    "code": "VEHICLE_NOT_AVAILABLE",
    "message": "The selected vehicle category is no longer available for this pickup window."
  }
}
```

---

### 2. Core API Endpoints

#### Authentication & Profile
- `POST /api/v1/auth/login`
  - Body: `{"login": "driver01@airport.pg", "password": "...", "device_id": "..."}`
  - Response: `{"token": "JWT_OR_SESSION_KEY", "user": {"id": 12, "name": "...", "role": "driver"}}`
- `POST /api/v1/auth/refresh`
  - Body: `{"refresh_token": "..."}`
- `GET /api/v1/auth/me`
  - Headers: `Authorization: Bearer <token>`

#### Airports & Master Data
- `GET /api/v1/airports`
  - Query params: `?active_only=true`
  - Returns list of active airports with geofences, operating hours, and instructions.
- `GET /api/v1/airports/{id}`
  - Detailed airport record including associated service zones and terminal instructions.
- `GET /api/v1/airports/{id}/zones`
  - List of service zones and risk ratings.

#### Quotations & Booking Engine
- `POST /api/v1/quotes`
  - Body:
    ```json
    {
      "airport_id": 1,
      "service_type": "airport_to_hotel",
      "pickup_datetime": "2026-10-08T14:30:00Z",
      "pickup_latitude": -6.5698,
      "pickup_longitude": 146.7262,
      "destination_latitude": -6.7275,
      "destination_longitude": 146.9966,
      "passenger_count": 2,
      "vehicle_category_id": 3,
      "security_required": true,
      "meet_greet_required": true
    }
    ```
  - Response: Detailed quotation breakdown (base fare, distance surcharge, security escort, total PGK).
- `POST /api/v1/bookings`
  - Create booking request with idempotency token (`Idempotency-Key`).
- `GET /api/v1/bookings/{id}`
  - Retrieve booking timeline, assigned resources, passenger manifest, and live status.
- `POST /api/v1/bookings/{id}/cancel`
  - Body: `{"reason": "Flight rescheduled"}`

#### Driver & Operational Dispatches
- `GET /api/v1/driver/assignments`
  - Active and upcoming jobs for the authenticated driver.
- `POST /api/v1/driver/assignments/{id}/events`
  - Body:
    ```json
    {
      "event_id": "uuid-v4-local-idempotency",
      "event_type": "driver_en_route | at_airport | passenger_verified | passenger_onboard | completed",
      "latitude": -6.5701,
      "longitude": 146.7280,
      "timestamp": "2026-10-08T13:45:10Z",
      "verification_code": "489210",
      "network_state": "offline_sync"
    }
    ```
- `POST /api/v1/driver/telematics/ping`
  - Batch GPS breadcrumbs for live vehicle tracking.

#### Incidents & SOS Command
- `POST /api/v1/incidents`
  - Body:
    ```json
    {
      "booking_id": 45,
      "category": "road_closure | breakdown | security_concern | sos",
      "severity": "high | critical",
      "description": "Bridge washed out along Markham Highway.",
      "latitude": -6.6500,
      "longitude": 146.8500
    }
    ```

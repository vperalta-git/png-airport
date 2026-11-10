# Arrivals and Departures

Two operational sections share the existing authenticated accounts, NestJS backend,
persistent test Firestore and resource locks. No duplicate backend or fleet is added.

| Section | Pickup | Drop-off | Driver pickup state |
| --- | --- | --- | --- |
| Arrivals | Nadzab Airport (LAE) | Customer's Lae address | AT_AIRPORT |
| Departures | Customer's Lae address | Nadzab Airport (LAE) | AT_PICKUP |

Customer, Control Room, Driver and Supervisor booking lists have Arrivals,
Departures and All transfers selectors, with Active/History/All within each section.
Customer booking entry is fixed to the selected section; choose the other section
before requesting a different kind of transfer. Lists and details show direction
and label the actual pickup and drop-off. Supervisor/Control Room counters are
calculated independently per direction by the backend.

## API and authorization

- GET /api/v1/bookings/arrivals: inbound bookings visible to the authenticated actor.
- GET /api/v1/bookings/departures: outbound bookings visible to that actor.
- GET /api/v1/bookings: retained scoped aggregate for existing clients.
- GET /api/v1/reports/dashboard: retains global totals and adds arrivals/departures
  summaries. Staff scope and permissions remain enforced by the backend.

The existing v1 direction values remain authoritative. Quotation identity fixes
booking direction, route and price. In the preserved v1 contract, destinationAddress
stores the city endpoint: arrival drop-off address or departure pickup address.
airportId identifies the airport endpoint. This compatibility meaning is explicit;
clients must label locations using direction rather than treating both as drop-off.

AT_PICKUP is an additive state in the shared TypeScript/Dart v1 enum. New outbound
trips cannot enter AT_AIRPORT; inbound trips cannot enter AT_PICKUP. Driver acceptance
and inspection are still required before travel. OTP verification is required at
the correct pickup state for each direction. Ordinary status updates cannot bypass
OTP. Both directions continue through transfer, arrival at destination and completion.
Payment state remains separate and is not changed to PAID by trip completion.

Shared locks prevent a driver or vehicle assigned to an arrival from also accepting
a departure. Existing records are not migrated, copied between systems or reset.
Refresh open website tabs after deployment to obtain the updated contract parser.

The offline source adapter supports both new queues and pickup states without HTTP.
Existing exported APK files have not been rebuilt by this website update.

No flight-provider integration, live flight schedules, airline check-in buffer,
commercial route prices or tax policy is invented. Flight metadata and approved
departure timing policy can be added after operator confirmation.

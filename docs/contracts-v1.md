# Canonical API contract v1

Authority: packages/types/src/v1.ts and requests.ts. Public exports come from
packages/types/src/index.ts; compiled package entrypoints are dist/index.js and
dist/index.d.ts. npm backend build/test commands compile this shared package first.
Dart DTOs are in png_transfer_flutter_core/lib/models/contracts_v1.dart.
Identical JSON fixtures are parsed by TypeScript, Nest and Dart tests. The enum
fixture also checks Dart/TS parity. Fixtures are test-only, not approved tariffs.

## Boundary

Every envelope contains schemaVersion: "1", success, data, error and meta
(timestamp, timezone=Pacific/Port_Moresby, requestId). Success has error:null;
failure has data:null and error:{code,message,details?}. Internal error text is not
exposed. Existing controllers remain unavailable until their services and
serializers adopt these DTOs in Batch B. No permissive legacy response adapter is
used to invent required fields.

Document IDs (including Firebase Auth/customer UIDs) are opaque nonempty strings,
never integers or numbers extracted from display references. Records contain
organizationId, branchId, airportId and customerId; an actor contains its uid,
canonical role, organizationId and explicit branchIds/airportIds. Claims are
server-managed; the guard never trusts requested roles, developer/worker headers
or self-writable profile roles.

## Roles

PASSENGER=Customer, DISPATCHER=Control Room, DRIVER=Driver,
SUPERVISOR=Manager/Supervisor. SUPER_ADMIN is distinct from operational supervision.
SECURITY, OPERATOR and CORPORATE_BOOKER remain reserved expansion roles without
implicit core permissions. No SYSTEM/development wildcard role exists in the v1
contract. SUPER_ADMIN does not bypass record/tenant scope automatically.

Permission definitions distinguish own booking, dispatch, assigned execution,
staff/resource management and audit review. canReadBooking checks organization,
branch/airport and customer ownership or driver assignment before staff scope.
These shared policy helpers define the contract; transactional service and
Firebase rule integration is Batch B work, not completed role authorization.

## Quotation and reservation

A quotation request is {schemaVersion,input}. Input includes airportId, direction,
vehicleCategory, securityEscortType, pickupDateTime, destinationAddress,
passengerCount and luggageCount. No client amount/status/tenant authority.

A quotation response contains id, scope, input, pricing, rateVersion, createdAt
and expiresAt. Expiry must follow creation. A booking request contains
schemaVersion, quotationId, idempotencyKey, paymentMethod and passengers, with an
optional customerId reserved for future authorized booking on behalf of a customer.
The active demo supports owning customers only and rejects another customerId.
The server binds scope/input/pricing to the quote and atomically enforces expiry,
single quote consumption, manifest count and idempotent intent retries.

Booking records contain id, referenceNumber, scope, quotationId, rateVersion,
input, pricing, passengers, status, payment, revision, createdAt and updatedAt.
Optional dispatch includes real driver/vehicle IDs and acceptedAt. OTP secrets
are not part of the general booking DTO. GET bookings/:id/pickup-credential is
available only to the owning customer. The assigned driver submits the code to
POST bookings/:id/verify-passenger; the verifier cannot fetch the code.

Pricing uses currency=PGK and safe integer subtotalMinor, taxMinor, totalMinor.
The sum must balance. The contract does not choose rates or tax policies. No
approved tariffs are configured. Test fixture taxMinor=0 is not a tax policy.

All times require an ISO timestamp with Z or an explicit offset and valid calendar
values. Display according to the configured airport timezone, not device local time.
revision is a nonnegative integer; subsequent service mutations must enforce
expected revisions/atomic conflicts.

Payment status is independent: PENDING, AUTHORIZED, PAID, FAILED, REFUNDED,
CANCELLED. PAID records require reference and verification time structurally;
that alone is not provider verification. Only a verified server payment workflow
may establish payment truth. Cash/card/PO selection cannot prove collection.

## Transition policy

The finite policy helper permits:

- Passenger: DRAFT -> QUOTATION -> BOOKING_REQUESTED.
- Dispatcher/Supervisor: BOOKING_REQUESTED -> AVAILABILITY_CONFIRMED -> CONFIRMED
  -> DISPATCHED.
- Assigned Driver: DISPATCHED -> DRIVER_EN_ROUTE -> AT_AIRPORT; then
  PASSENGER_VERIFIED -> TRANSFER_IN_PROGRESS -> ARRIVED_DESTINATION -> COMPLETED.
- Supervisor: COMPLETED -> CLOSED.
- Owning Passenger/authorized Dispatcher/Supervisor: early cancellation from
  BOOKING_REQUESTED, AVAILABILITY_CONFIRMED, CONFIRMED or DISPATCHED.

AT_AIRPORT -> PASSENGER_VERIFIED is never a generic status mutation. A dedicated
backend verification operation must atomically validate assignment, challenge,
expiry, attempts and single use. Driver departure additionally requires acceptance.
Permissions, state, scope, revision, resource conflicts and verification checks
must all be enforced in the service transaction. The policy definition does not
itself implement the transaction. The current BookingsService now performs those
checks atomically, with explicit acceptance, resource locks and audited OTP reissue.

## Migration boundary

Legacy UI/domain types are retained explicitly under packages/types/src/legacy.ts
and the Legacy namespace. Dart legacy presentation models and the old internal
Nest entities are preserved while legacy activation is blocked. They are not
competing v1 wire contracts. Four primary entrypoints now share the versioned
mobile demo screens and NestJS workflow services. Legacy numeric/snake_case
payload paths and direct operational Firestore writes remain unactivated.
The foundation guard permits only explicitly upgraded controllers. Direct Firebase
client rules remain deny-all; operational reads and mutations go through the API.

## Current workflow request extensions

- Assignment: POST dispatch/:id/assign with driverId, vehicleId, expectedRevision.
- Acceptance: POST dispatch/:id/acknowledge with expectedRevision and inspection
  booleans seatbelts, tyres, fuel, radio, all true.
- Status: PATCH bookings/:id/status with status and expectedRevision.
- Pickup verification: POST bookings/:id/verify-passenger with six-digit string
  code and expectedRevision. Five failed attempts persist and lock the challenge.
- Supervisor reissue: POST bookings/:id/reset-otp with reason and expectedRevision.
- Details: GET bookings/:id/details returns booking, actual assignmentInfo and
  chronological revision/step-ordered events. It contains no OTP credential.
- Configuration: GET config exposes the Lae catalog and explicit demo pricing flag.

These use the existing v1 envelope and string document IDs. Payment mutation,
GPS, provider callbacks and offline acknowledgments remain unavailable.

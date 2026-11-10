const { test } = require("node:test");
const assert = require("node:assert/strict");
const {
  parseBooking,
  parseQuotation,
  canReadBooking,
  canTransition,
  timestamp,
} = require("../dist");
const booking = require("../fixtures/booking.v1.json");
const quote = require("../fixtures/quotation.v1.json");
test("versioned enum fixture stays synchronized with the authoritative TypeScript definitions", () => {
  const c = require("../dist"),
    d = require("../fixtures/definition.v1.json");
  assert.deepEqual(d, {
    schemaVersion: c.CONTRACT_VERSION,
    roles: c.ROLES,
    bookingStatuses: c.BOOKING_STATUSES,
    paymentStatuses: c.PAYMENT_STATUSES,
    vehicleCategories: c.VEHICLE_CATEGORIES,
    escortTypes: c.ESCORT_TYPES,
    directions: c.DIRECTIONS,
  });
});
test("TypeScript parses the same versioned fixtures as Nest and Dart", () => {
  assert.equal(parseBooking(booking).id, "BK-test-only");
  assert.equal(parseQuotation(quote).pricing.totalMinor, 12345);
});
test("contracts reject numeric/missing IDs, invalid enums, money and timestamps", () => {
  for (const patch of [
    { id: 1 },
    { id: "" },
    { schemaVersion: "2" },
    { status: "completed" },
    { revision: 1.5 },
    { customerId: "" },
    { pricing: { ...booking.pricing, totalMinor: 1 } },
    { createdAt: "2030-01-14 00:00:00" },
    { payment: { status: "PAID" } },
    { input: { ...booking.input, airportId: "other" } },
  ]) {
    assert.throws(() => parseBooking({ ...booking, ...patch }));
  }
  for (const time of [
    "2030-02-30T00:00:00Z",
    "2030-01-14T25:00:00Z",
    "2030-01-14T00:00:00+99:00",
  ])
    assert.throws(() => timestamp(time));
});
test("scope and driver assignment boundaries are explicit and fail closed", () => {
  const actor = {
    uid: booking.customerId,
    role: "PASSENGER",
    organizationId: booking.organizationId,
    branchIds: [booking.branchId],
    airportIds: [booking.airportId],
  };
  assert.equal(canReadBooking(actor, booking), true);
  for (const patch of [
    { uid: "another-customer" },
    { organizationId: "other-org" },
    { branchIds: [] },
    { airportIds: [] },
    { role: "SECURITY" },
  ])
    assert.equal(canReadBooking({ ...actor, ...patch }, booking), false);
  assert.equal(canReadBooking({ ...actor, role: "DRIVER" }, booking), false);
});
test("transition policy separates verification and finance from trip progress", () => {
  assert.equal(
    canTransition("DRIVER", "AT_AIRPORT", "PASSENGER_VERIFIED"),
    false,
  );
  assert.equal(canTransition("PASSENGER", "CONFIRMED", "CANCELLED"), true);
  assert.equal(
    canTransition("PASSENGER", "TRANSFER_IN_PROGRESS", "CANCELLED"),
    false,
  );
  assert.equal(
    canTransition("DRIVER", "ARRIVED_DESTINATION", "COMPLETED"),
    true,
  );
  assert.equal(canTransition("DISPATCHER", "COMPLETED", "CLOSED"), false);
  assert.equal(canTransition("SUPERVISOR", "COMPLETED", "CLOSED"), true);
});

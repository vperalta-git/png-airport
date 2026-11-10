// Explicitly opt-in acceptance against the approved, isolated Firebase TEST project.
// Passwords come only from an ignored local file; tokens stay in memory.
import assert from "node:assert/strict";
import { readFileSync, writeFileSync } from "node:fs";
import { randomUUID, randomBytes } from "node:crypto";

const projectId = "aerotrans-png-test-7d7128";
const origin = "https://aerotrans-png-test-api-7d7128.vercel.app";
if (!process.argv.includes("--allow-test-writes"))
  throw new Error(
    "Pass --allow-test-writes to create labelled acceptance records in the isolated test project.",
  );
const sdk = JSON.parse(
  readFileSync(".local-tools/hosted-test/firebase-web.json", "utf8"),
);
const sheet = JSON.parse(
  readFileSync(".local-tools/hosted-test/accounts.json", "utf8"),
);
assert.equal(sdk.projectId, projectId);
assert.equal(sheet.projectId, projectId);
const evidence = {
  projectId,
  origin,
  startedAt: new Date().toISOString(),
  checks: [],
  bookingIds: [],
  success: false,
};
const save = () =>
  writeFileSync(
    ".local-tools/hosted-test/api-acceptance.json",
    JSON.stringify(evidence, null, 2) + "\n",
  );
const pass = (label) => {
  evidence.checks.push(label);
  save();
  console.log("PASS " + label);
};
async function call(method, path, token, data, expected = 200) {
  const response = await fetch(origin + "/api/v1" + path, {
    method,
    redirect: "error",
    signal: AbortSignal.timeout(45000),
    headers: {
      ...(token ? { Authorization: "Bearer " + token } : {}),
      ...(data === undefined ? {} : { "Content-Type": "application/json" }),
    },
    body: data === undefined ? undefined : JSON.stringify(data),
  });
  const result = await response.json();
  assert.equal(
    response.status,
    expected,
    method + " " + path + " status; error code: " + result.error?.code,
  );
  assert.equal(result.schemaVersion, "1");
  if (expected < 400) assert.equal(result.success, true);
  return result.data;
}
async function signIn(account) {
  const url = new URL(
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword",
  );
  url.searchParams.set("key", sdk.apiKey);
  const response = await fetch(url, {
    method: "POST",
    redirect: "error",
    signal: AbortSignal.timeout(30000),
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: account.email,
      password: account.password,
      returnSecureToken: true,
    }),
  });
  const result = await response.json();
  assert.equal(
    response.status,
    200,
    "Firebase sign-in failed for " +
      account.role +
      " (" +
      result.error?.message +
      ")",
  );
  assert.equal(
    JSON.parse(
      Buffer.from(result.idToken.split(".")[1], "base64url").toString(),
    ).aud,
    projectId,
  );
  return result.idToken;
}
try {
  const health = await call("GET", "/health");
  assert.equal(health.projectId, projectId);
  assert.equal(health.environment, "staging");
  pass("HTTPS backend identity matches the isolated test project");
  const preflight = await fetch(origin + "/api/v1/auth/me", {
    method: "OPTIONS",
    redirect: "error",
    headers: {
      Origin: "https://png-airport-kappa.vercel.app",
      "Access-Control-Request-Method": "GET",
      "Access-Control-Request-Headers": "authorization",
    },
  });
  assert.equal(
    preflight.headers.get("access-control-allow-origin"),
    "https://png-airport-kappa.vercel.app",
  );
  pass("Browser CORS permits the configured website");
  await call("GET", "/bookings", undefined, undefined, 401);
  const people = {};
  for (const account of sheet.accounts) {
    const token = await signIn(account);
    const profile = await call("GET", "/auth/me", token);
    assert.equal(profile.uid, account.uid);
    assert.equal(profile.role, account.role);
    people[account.role] = { ...account, token };
  }
  pass(
    "All four accounts sign in through Firebase and resolve their server roles",
  );
  await call("GET", "/users", people.PASSENGER.token, undefined, 403);
  await call("GET", "/reports/audit", people.DRIVER.token, undefined, 403);
  await call(
    "POST",
    "/auth/register",
    undefined,
    {
      schemaVersion: "1",
      fullName: "TEST invalid privilege request",
      email: "invalid@example.invalid",
      password: "TEST-only-never-used",
      role: "SUPERVISOR",
    },
    400,
  );
  pass(
    "Anonymous access and customer/driver privilege escalation are rejected",
  );
  const registration = {
    schemaVersion: "1",
    fullName: "AUTOMATED ACCEPTANCE Customer",
    email: "acceptance-" + randomUUID() + "@aerotrans-test.invalid",
    password: randomBytes(20).toString("base64url") + "!7a",
  };
  const profile = await call(
    "POST",
    "/auth/register",
    undefined,
    registration,
    201,
  );
  assert.equal(profile.role, "PASSENGER");
  const customer = {
    uid: profile.uid,
    token: await signIn({ ...registration, role: "PASSENGER" }),
  };
  evidence.registrationUid = profile.uid;
  save();
  pass("Customer registration creates a real scoped passenger account");
  const reserve = async (direction = "INBOUND_AIRPORT_TO_CITY") => {
    const quote = await call(
      "POST",
      "/quotes",
      customer.token,
      {
        schemaVersion: "1",
        input: {
          airportId: "airport_nadzab_lae",
          direction,
          vehicleCategory: "STANDARD_SEDAN",
          securityEscortType: "NONE",
          pickupDateTime: new Date(Date.now() + 7200000).toISOString(),
          destinationAddress: "AUTOMATED ACCEPTANCE TEST ONLY - Lae",
          passengerCount: 1,
          luggageCount: 1,
        },
      },
      201,
    );
    assert.equal(quote.pricing.totalMinor, 10000);
    assert.equal(quote.pricing.currency, "PGK");
    const intent = {
      schemaVersion: "1",
      quotationId: quote.id,
      idempotencyKey: randomUUID(),
      paymentMethod: "CASH_ON_BOARD",
      passengers: [
        { fullName: "AUTOMATED ACCEPTANCE TEST", phone: "+67570000000" },
      ],
    };
    const booking = await call(
      "POST",
      "/bookings",
      customer.token,
      intent,
      201,
    );
    evidence.bookingIds.push(booking.id);
    save();
    return { booking, intent };
  };
  const { booking: initial, intent } = await reserve();
  let booking = initial;
  assert.equal(booking.payment.status, "PENDING");
  assert.equal(booking.dispatch, undefined);
  assert.equal(
    (await call("POST", "/bookings", customer.token, intent, 201)).id,
    booking.id,
  );
  await call(
    "GET",
    "/bookings/" + booking.id,
    people.PASSENGER.token,
    undefined,
    404,
  );
  await call(
    "GET",
    "/bookings/" + booking.id,
    people.DRIVER.token,
    undefined,
    404,
  );
  pass(
    "Server quote, integer PGK fare, idempotent booking, ownership and manual assignment",
  );
  const drivers = await call(
    "GET",
    "/resources/drivers",
    people.DISPATCHER.token,
  );
  const vehicles = await call(
    "GET",
    "/resources/vehicles",
    people.DISPATCHER.token,
  );
  const driver = drivers.find((d) => d.id === people.DRIVER.uid && d.available);
  const vehicle = vehicles.find(
    (v) => v.id === "hosted-demo-sedan" && v.available,
  );
  assert.ok(
    driver,
    "Test driver is unavailable; preserve existing work and resolve its active trip",
  );
  assert.ok(
    vehicle,
    "Test sedan is unavailable; preserve existing work and resolve its active trip",
  );
  booking = await call(
    "POST",
    "/dispatch/" + booking.id + "/assign",
    people.DISPATCHER.token,
    {
      driverId: driver.id,
      vehicleId: vehicle.id,
      expectedRevision: booking.revision,
    },
    201,
  );
  assert.equal(booking.dispatch.assignedDriverId, people.DRIVER.uid);
  await call(
    "PATCH",
    "/bookings/" + booking.id + "/status",
    people.DRIVER.token,
    { status: "DRIVER_EN_ROUTE", expectedRevision: booking.revision },
    409,
  );
  booking = await call(
    "POST",
    "/dispatch/" + booking.id + "/acknowledge",
    people.DRIVER.token,
    {
      inspection: { seatbelts: true, tyres: true, fuel: true, radio: true },
      expectedRevision: booking.revision,
    },
    201,
  );
  for (const status of ["DRIVER_EN_ROUTE", "AT_AIRPORT"])
    booking = await call(
      "PATCH",
      "/bookings/" + booking.id + "/status",
      people.DRIVER.token,
      { status, expectedRevision: booking.revision },
    );
  pass(
    "Control Room assigns available resources; driver acceptance precedes progress",
  );
  const departureReservation = await reserve("OUTBOUND_CITY_TO_AIRPORT");
  await call(
    "POST",
    "/dispatch/" + departureReservation.booking.id + "/assign",
    people.DISPATCHER.token,
    {
      driverId: driver.id,
      vehicleId: vehicle.id,
      expectedRevision: departureReservation.booking.revision,
    },
    409,
  );
  pass(
    "Arrival and departure dispatch share resource locks and prevent cross-queue double booking",
  );
  await call(
    "GET",
    "/bookings/" + booking.id + "/pickup-credential",
    people.DRIVER.token,
    undefined,
    403,
  );
  const pickup = await call(
    "GET",
    "/bookings/" + booking.id + "/pickup-credential",
    customer.token,
  );
  await call(
    "POST",
    "/bookings/" + booking.id + "/verify-passenger",
    people.DRIVER.token,
    {
      code: pickup.code === "000000" ? "111111" : "000000",
      expectedRevision: booking.revision,
    },
    400,
  );
  booking = await call(
    "POST",
    "/bookings/" + booking.id + "/verify-passenger",
    people.DRIVER.token,
    { code: pickup.code, expectedRevision: booking.revision },
    201,
  );
  await call(
    "POST",
    "/bookings/" + booking.id + "/verify-passenger",
    people.DRIVER.token,
    { code: pickup.code, expectedRevision: booking.revision },
    409,
  );
  for (const status of [
    "TRANSFER_IN_PROGRESS",
    "ARRIVED_DESTINATION",
    "COMPLETED",
  ])
    booking = await call(
      "PATCH",
      "/bookings/" + booking.id + "/status",
      people.DRIVER.token,
      { status, expectedRevision: booking.revision },
    );
  assert.equal(booking.status, "COMPLETED");
  assert.equal(booking.payment.status, "PENDING");
  pass(
    "Backend pickup OTP rejects wrong/replayed codes; completion does not confirm payment",
  );
  const history = await call("GET", "/bookings", people.DRIVER.token);
  assert.ok(
    history.some((b) => b.id === booking.id && b.status === "COMPLETED"),
  );
  assert.ok(
    history.every((b) => b.dispatch?.assignedDriverId === people.DRIVER.uid),
  );
  const cancelled = await reserve();
  let departure = await call(
    "POST",
    "/dispatch/" + departureReservation.booking.id + "/assign",
    people.DISPATCHER.token,
    {
      driverId: driver.id,
      vehicleId: vehicle.id,
      expectedRevision: departureReservation.booking.revision,
    },
    201,
  );
  departure = await call(
    "POST",
    "/dispatch/" + departure.id + "/acknowledge",
    people.DRIVER.token,
    {
      inspection: { seatbelts: true, tyres: true, fuel: true, radio: true },
      expectedRevision: departure.revision,
    },
    201,
  );
  departure = await call(
    "PATCH",
    "/bookings/" + departure.id + "/status",
    people.DRIVER.token,
    { status: "DRIVER_EN_ROUTE", expectedRevision: departure.revision },
  );
  await call(
    "PATCH",
    "/bookings/" + departure.id + "/status",
    people.DRIVER.token,
    { status: "AT_AIRPORT", expectedRevision: departure.revision },
    409,
  );
  departure = await call(
    "PATCH",
    "/bookings/" + departure.id + "/status",
    people.DRIVER.token,
    { status: "AT_PICKUP", expectedRevision: departure.revision },
  );
  const departureCode = await call(
    "GET",
    "/bookings/" + departure.id + "/pickup-credential",
    customer.token,
  );
  departure = await call(
    "POST",
    "/bookings/" + departure.id + "/verify-passenger",
    people.DRIVER.token,
    { code: departureCode.code, expectedRevision: departure.revision },
    201,
  );
  for (const status of [
    "TRANSFER_IN_PROGRESS",
    "ARRIVED_DESTINATION",
    "COMPLETED",
  ])
    departure = await call(
      "PATCH",
      "/bookings/" + departure.id + "/status",
      people.DRIVER.token,
      { status, expectedRevision: departure.revision },
    );
  assert.equal(departure.payment.status, "PENDING");
  const arrivals = await call(
    "GET",
    "/bookings/arrivals",
    people.DISPATCHER.token,
  );
  const departures = await call(
    "GET",
    "/bookings/departures",
    people.DISPATCHER.token,
  );
  assert.ok(
    arrivals.every((b) => b.input.direction === "INBOUND_AIRPORT_TO_CITY"),
  );
  assert.ok(
    departures.every((b) => b.input.direction === "OUTBOUND_CITY_TO_AIRPORT"),
  );
  assert.ok(
    departures.some((b) => b.id === departure.id && b.status === "COMPLETED"),
  );
  assert.ok(
    !(await call("GET", "/bookings/departures", people.PASSENGER.token)).some(
      (b) => b.id === departure.id,
    ),
  );
  pass(
    "Departure completes customer pickup, OTP and airport drop-off; queues retain ownership isolation",
  );
  assert.equal(
    (
      await call(
        "PATCH",
        "/bookings/" + cancelled.booking.id + "/status",
        customer.token,
        { status: "CANCELLED", expectedRevision: cancelled.booking.revision },
      )
    ).status,
    "CANCELLED",
  );
  pass(
    "Driver history contains only assigned trips; customer cancellation is persisted",
  );
  const summary = await call(
    "GET",
    "/reports/dashboard",
    people.SUPERVISOR.token,
  );
  const audit = await call("GET", "/reports/audit", people.SUPERVISOR.token);
  assert.ok(summary.completedTrips >= 1);
  assert.ok(summary.cancelledTrips >= 1);
  assert.ok(summary.arrivals.completedTrips >= 1);
  assert.ok(summary.departures.completedTrips >= 1);
  assert.ok(Array.isArray(audit));
  assert.ok(
    (await call("GET", "/users", people.SUPERVISOR.token)).some(
      (u) => u.uid === customer.uid,
    ),
  );
  pass("Supervisor sees real operational summary, staff and audit responses");
  evidence.success = true;
  evidence.completedAt = new Date().toISOString();
  save();
  console.log(
    "Hosted four-role API acceptance passed. Evidence contains no passwords or tokens.",
  );
} catch (error) {
  evidence.failure = error.message;
  save();
  console.error("FAIL " + error.message);
  process.exitCode = 1;
}

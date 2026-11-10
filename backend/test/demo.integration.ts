import { Test } from "@nestjs/testing";
import { INestApplication } from "@nestjs/common";
import request from "supertest";
import { randomUUID } from "node:crypto";
import { AppModule } from "../src/app.module";
import { FirebaseService } from "../src/firebase/firebase.service";
import { setupApplication } from "../src/app.setup";
import { DEMO_SCOPE } from "../src/common/workflow";
jest.setTimeout(90000);
describe("isolated four-role mobile demo API", () => {
  let app: INestApplication, firebase: FirebaseService;
  const org = "test-" + randomUUID(),
    uids: string[] = [],
    bookIds: string[] = [],
    plates: string[] = [];
  const password = "TEST-ONLY-" + randomUUID() + "!7a";
  const people: Record<string, any> = {};
  const call = async (
    method: string,
    path: string,
    who?: any,
    data?: unknown,
    expected = 200,
  ) => {
    let operation = request(app.getHttpServer())[method]("/api/v1" + path);
    if (who) operation = operation.set("Authorization", "Bearer " + who.token);
    if (data !== undefined) operation = operation.send(data);
    const result = await operation;
    expect({ path, status: result.status, error: result.body.error }).toEqual(
      expect.objectContaining({ status: expected }),
    );
    return result.body.data;
  };
  const signin = async (address: string) => {
    const response = await fetch(
      "http://" +
        process.env.FIREBASE_AUTH_EMULATOR_HOST +
        "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-emulator-key",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: address,
          password,
          returnSecureToken: true,
        }),
      },
    );
    const data = await response.json();
    expect(response.status).toBe(200);
    return data.idToken;
  };
  const identity = async (role: string, name: string, scopeOrg = org) => {
    const user = await firebase.auth.createUser({
      email: randomUUID() + "@example.invalid",
      password,
      displayName: name,
    });
    uids.push(user.uid);
    await firebase.auth.setCustomUserClaims(user.uid, {
      role,
      organizationId: scopeOrg,
      branchIds: [DEMO_SCOPE.branchId],
      airportIds: [DEMO_SCOPE.airportId],
    });
    await firebase.firestore
      .collection("users")
      .doc(user.uid)
      .set({
        uid: user.uid,
        role,
        fullName: name,
        email: user.email,
        active: true,
        available: role === "DRIVER",
        ...DEMO_SCOPE,
        organizationId: scopeOrg,
        createdAt: new Date().toISOString(),
      });
    return { uid: user.uid, token: await signin(user.email) };
  };
  const reserve = async (key = randomUUID()) => {
    const quote = await call(
      "post",
      "/quotes",
      people.customer,
      {
        schemaVersion: "1",
        input: {
          airportId: DEMO_SCOPE.airportId,
          direction: "INBOUND_AIRPORT_TO_CITY",
          vehicleCategory: "STANDARD_SEDAN",
          securityEscortType: "NONE",
          pickupDateTime: new Date(Date.now() + 3600000).toISOString(),
          destinationAddress: "TEST ONLY Lae destination",
          passengerCount: 1,
          luggageCount: 1,
        },
      },
      201,
    );
    const intent = {
      schemaVersion: "1",
      quotationId: quote.id,
      idempotencyKey: key,
      paymentMethod: "CASH_ON_BOARD",
      passengers: [{ fullName: "TEST passenger", phone: "+67570000000" }],
    };
    const booking = await call(
      "post",
      "/bookings",
      people.customer,
      intent,
      201,
    );
    bookIds.push(booking.id);
    return { booking, quote, intent };
  };
  beforeAll(async () => {
    if (
      !process.env.FIRESTORE_EMULATOR_HOST ||
      process.env.AEROTRANS_DEMO_RATES !== "true"
    )
      throw new Error("Use npm run demo:test with the local emulators running");
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication();
    setupApplication(app);
    await app.init();
    firebase = app.get(FirebaseService);
    people.manager = await identity("SUPERVISOR", "Test manager");
    people.control = await identity("DISPATCHER", "Test control");
    people.driver = await identity("DRIVER", "Test driver A");
    people.otherDriver = await identity("DRIVER", "Test driver B");
    people.foreign = await identity(
      "PASSENGER",
      "Foreign customer",
      "foreign-" + org,
    );
    // Exercise actual public registration; move only this owned fixture into the
    // isolated test organization before login to avoid touching other demo data.
    const address = randomUUID() + "@example.invalid";
    const profile = await call(
      "post",
      "/auth/register",
      undefined,
      {
        schemaVersion: "1",
        fullName: "Test customer",
        email: address,
        password,
      },
      201,
    );
    uids.push(profile.uid);
    await firebase.auth.setCustomUserClaims(profile.uid, {
      role: "PASSENGER",
      organizationId: org,
      branchIds: [DEMO_SCOPE.branchId],
      airportIds: [DEMO_SCOPE.airportId],
    });
    await firebase.firestore
      .collection("users")
      .doc(profile.uid)
      .update({ organizationId: org });
    people.customer = { uid: profile.uid, token: await signin(address) };
  });
  afterAll(async () => {
    if (!firebase) return;
    for (const collection of [
      "quotations",
      "bookings",
      "booking_events",
      "dispatch_assignments",
      "resource_locks",
      "vehicles",
      "audit_logs",
    ]) {
      const rows = await firebase.firestore
        .collection(collection)
        .where("organizationId", "==", org)
        .get();
      for (const doc of rows.docs) await doc.ref.delete();
    }
    for (const bookingId of bookIds)
      await firebase.firestore
        .collection("pickup_challenges")
        .doc(bookingId)
        .delete();
    const requests = await firebase.firestore
      .collection("booking_requests")
      .where("customerId", "==", people.customer?.uid ?? "none")
      .get();
    for (const doc of requests.docs) await doc.ref.delete();
    for (const plate of plates)
      await firebase.firestore
        .collection("vehicle_plates")
        .doc(encodeURIComponent(org + ":" + plate))
        .delete();
    for (const uid of uids) {
      await firebase.firestore.collection("users").doc(uid).delete();
      await firebase.auth.deleteUser(uid);
    }
    await app?.close();
  });
  it("authenticates real emulator accounts, rejects role injection and enforces four-role workflow/OTP/payment integrity", async () => {
    await call("get", "/bookings", undefined, undefined, 401);
    await call(
      "post",
      "/auth/register",
      undefined,
      {
        schemaVersion: "1",
        fullName: "No staff",
        email: "invalid@example.invalid",
        password,
        role: "SUPERVISOR",
      },
      400,
    );
    expect((await call("get", "/auth/me", people.customer)).role).toBe(
      "PASSENGER",
    );
    await call("get", "/users", people.customer, undefined, 403);
    const plate = "TEST-" + randomUUID().slice(0, 12);
    plates.push(plate);
    const vehicle = await call(
      "post",
      "/resources/vehicles",
      people.manager,
      {
        makeModel: "TEST ONLY sedan",
        registrationPlate: plate,
        category: "STANDARD_SEDAN",
      },
      201,
    );
    await call(
      "post",
      "/resources/vehicles",
      people.manager,
      {
        makeModel: "Duplicate",
        registrationPlate: plate,
        category: "STANDARD_SEDAN",
      },
      409,
    );
    const { booking: first, quote, intent } = await reserve();
    let b = first;
    expect(b.payment.status).toBe("PENDING");
    expect(b.dispatch).toBeUndefined();
    expect(b.pricing.totalMinor).toBe(10000);
    await firebase.firestore
      .collection("quotations")
      .doc(quote.id)
      .update({
        expiresAt: new Date(Date.now() - 1000).toISOString(),
        createdAt: new Date(Date.now() - 60000).toISOString(),
      });
    const retry = await call("post", "/bookings", people.customer, intent, 201);
    expect(retry.id).toBe(b.id);
    await call("get", "/bookings/" + b.id, people.foreign, undefined, 404);
    expect(await call("get", "/bookings", people.driver)).toEqual([]);
    b = await call(
      "post",
      "/dispatch/" + b.id + "/assign",
      people.control,
      {
        driverId: people.driver.uid,
        vehicleId: vehicle.id,
        expectedRevision: b.revision,
      },
      201,
    );
    await call(
      "patch",
      "/bookings/" + b.id + "/status",
      people.driver,
      { status: "DRIVER_EN_ROUTE", expectedRevision: b.revision },
      409,
    );
    const inspection = {
      seatbelts: true,
      tyres: true,
      fuel: true,
      radio: true,
    };
    b = await call(
      "post",
      "/dispatch/" + b.id + "/acknowledge",
      people.driver,
      { inspection, expectedRevision: b.revision },
      201,
    );
    b = await call(
      "post",
      "/dispatch/" + b.id + "/assign",
      people.control,
      {
        driverId: people.otherDriver.uid,
        vehicleId: vehicle.id,
        expectedRevision: b.revision,
      },
      201,
    );
    expect(b.dispatch.acceptedAt).toBeUndefined();
    await call("get", "/bookings/" + b.id, people.driver, undefined, 404);
    b = await call(
      "post",
      "/dispatch/" + b.id + "/acknowledge",
      people.otherDriver,
      { inspection, expectedRevision: b.revision },
      201,
    );
    for (const status of ["DRIVER_EN_ROUTE", "AT_AIRPORT"])
      b = await call(
        "patch",
        "/bookings/" + b.id + "/status",
        people.otherDriver,
        { status, expectedRevision: b.revision },
      );
    await call(
      "patch",
      "/bookings/" + b.id + "/status",
      people.otherDriver,
      { status: "PASSENGER_VERIFIED", expectedRevision: b.revision },
      409,
    );
    await call(
      "get",
      "/bookings/" + b.id + "/pickup-credential",
      people.otherDriver,
      undefined,
      403,
    );
    const code = await call(
      "get",
      "/bookings/" + b.id + "/pickup-credential",
      people.customer,
    );
    for (let i = 0; i < 5; i++)
      await call(
        "post",
        "/bookings/" + b.id + "/verify-passenger",
        people.otherDriver,
        {
          code: code.code === "000000" ? "111111" : "000000",
          expectedRevision: b.revision,
        },
        i === 4 ? 429 : 400,
      );
    expect(
      (
        await call(
          "get",
          "/bookings/" + b.id + "/pickup-credential",
          people.customer,
        )
      ).available,
    ).toBe(false);
    b = await call(
      "post",
      "/bookings/" + b.id + "/reset-otp",
      people.manager,
      { reason: "TEST ONLY locked code", expectedRevision: b.revision },
      201,
    );
    const reissued = await call(
      "get",
      "/bookings/" + b.id + "/pickup-credential",
      people.customer,
    );
    b = await call(
      "post",
      "/bookings/" + b.id + "/verify-passenger",
      people.otherDriver,
      { code: reissued.code, expectedRevision: b.revision },
      201,
    );
    expect(b.status).toBe("PASSENGER_VERIFIED");
    await call(
      "post",
      "/bookings/" + b.id + "/verify-passenger",
      people.otherDriver,
      { code: reissued.code, expectedRevision: b.revision },
      409,
    );
    for (const status of [
      "TRANSFER_IN_PROGRESS",
      "ARRIVED_DESTINATION",
      "COMPLETED",
    ])
      b = await call(
        "patch",
        "/bookings/" + b.id + "/status",
        people.otherDriver,
        { status, expectedRevision: b.revision },
      );
    expect(b.payment.status).toBe("PENDING");
    expect(
      (await call("get", "/resources/drivers", people.otherDriver))[0]
        .completedTrips,
    ).toBe(1);
    expect(
      (
        await call("get", "/bookings/" + b.id + "/details", people.customer)
      ).events.some((e) => e.description === "PASSENGER_VERIFIED"),
    ).toBe(true);
    const second = await reserve(),
      third = await reserve();
    const responses = await Promise.all(
      [second, third].map(async ({ booking }) => {
        const res = await request(app.getHttpServer())
          .post("/api/v1/dispatch/" + booking.id + "/assign")
          .set("Authorization", "Bearer " + people.control.token)
          .send({
            driverId: people.driver.uid,
            vehicleId: vehicle.id,
            expectedRevision: booking.revision,
          });
        return res;
      }),
    );
    expect(responses.map((r) => r.status).sort()).toEqual([201, 409]);
    // Closing an earlier completed trip must not unlock a newer assignment.
    b = await call("patch", "/bookings/" + b.id + "/status", people.manager, {
      status: "CLOSED",
      expectedRevision: b.revision,
    });
    expect(
      (
        await firebase.firestore
          .collection("resource_locks")
          .doc("driver_" + people.driver.uid)
          .get()
      ).data()?.bookingId,
    ).toBeDefined();
    for (const reservation of [second, third]) {
      const current = await call(
        "get",
        "/bookings/" + reservation.booking.id,
        people.customer,
      );
      await call(
        "patch",
        "/bookings/" + current.id + "/status",
        people.customer,
        { status: "CANCELLED", expectedRevision: current.revision },
      );
    }
    const summary = await call("get", "/reports/dashboard", people.manager);
    expect(summary.completedTrips).toBe(1);
    expect(summary.cancelledTrips).toBe(2);
    expect(summary.verifiedPayments).toBe(0);
    expect(
      (await call("get", "/reports/audit", people.manager)).length,
    ).toBeGreaterThan(0);
    const employee = await call(
      "post",
      "/users",
      people.manager,
      {
        fullName: "Test staff",
        email: randomUUID() + "@example.invalid",
        password,
        role: "DRIVER",
        phone: "70000000",
      },
      201,
    );
    uids.push(employee.uid);
    expect(employee.phone).toBe("+67570000000");
    const employeeActor = {
      uid: employee.uid,
      token: await signin(employee.email),
    };
    await call("patch", "/resources/drivers/" + employee.uid, people.manager, {
      available: true,
    });
    await call("patch", "/users/" + employee.uid, people.manager, {
      active: false,
    });
    await call("get", "/bookings", employeeActor, undefined, 401);
    await call(
      "patch",
      "/users/" + people.manager.uid,
      people.manager,
      { active: false },
      400,
    );
    await call("patch", "/resources/vehicles/" + vehicle.id, people.manager, {
      status: "MAINTENANCE",
    });
    expect(
      (await call("get", "/reports/audit", people.manager)).some(
        (a) => a.action === "VEHICLE_UPDATED" && a.organizationId === org,
      ),
    ).toBe(true);
  });
});

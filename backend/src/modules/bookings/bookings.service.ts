import {
  Injectable,
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  HttpException,
} from "@nestjs/common";
import {
  randomUUID,
  randomInt,
  randomBytes,
  createHash,
  timingSafeEqual,
} from "node:crypto";
import { Transaction } from "firebase-admin/firestore";
import {
  Actor,
  Booking,
  BookingRequest,
  BookingStatus as Status,
  parseBooking,
  parseQuotation,
  canReadBooking,
  canTransition,
} from "@png-transfer/types";
import { FirebaseService } from "../../firebase/firebase.service";
import {
  body,
  text,
  id,
  phone,
  email,
  inScope,
  staff,
  now,
} from "../../common/workflow";
export type BookingEntity = Booking;
export type BookingStatus = Status;
export interface BookingEvent {
  id: string;
  bookingId: string;
  actorId: string;
  actorRole: string;
  fromStatus?: Status;
  toStatus: Status;
  description: string;
  timestamp: string;
  revision: number;
  step: number;
  organizationId: string;
  branchId: string;
  airportId: string;
}
const hash = (value: string) =>
  createHash("sha256").update(value).digest("hex");
const terminal = (status: Status) =>
  ["COMPLETED", "CLOSED", "CANCELLED"].includes(status);
@Injectable()
export class BookingsService {
  constructor(private readonly firebase: FirebaseService) {}
  private get db() {
    return this.firebase.firestore;
  }
  private visible(actor: Actor, booking: Booking) {
    if (!canReadBooking(actor, booking))
      throw new NotFoundException("Booking not found");
  }
  private revision(booking: Booking, value: unknown) {
    if (!Number.isSafeInteger(value) || value !== booking.revision)
      throw new ConflictException({
        code: "REVISION_CONFLICT",
        message: "This booking changed. Refresh and try again.",
      });
  }
  private event(
    tx: Transaction,
    booking: Booking,
    actor: Actor,
    description: string,
    fromStatus?: Status,
    step = 3,
  ) {
    const ref = this.db.collection("booking_events").doc();
    const event: BookingEvent = {
      id: ref.id,
      bookingId: booking.id,
      actorId: actor.uid,
      actorRole: actor.role,
      organizationId: booking.organizationId,
      branchId: booking.branchId,
      airportId: booking.airportId,
      fromStatus,
      toStatus: booking.status,
      description,
      timestamp: now(),
      revision: booking.revision,
      step,
    };
    tx.create(ref, event);
    tx.create(this.db.collection("audit_logs").doc(), {
      ...event,
      action: description,
      resourceId: booking.id,
    });
  }
  private save(
    tx: Transaction,
    booking: Booking,
    actor: Actor,
    description: string,
    from: Status,
  ) {
    booking.updatedAt = now();
    booking.revision++;
    tx.set(
      this.db.collection("bookings").doc(booking.id),
      parseBooking(booking),
    );
    this.event(tx, booking, actor, description, from);
    return booking;
  }
  async create(request: BookingRequest, actor: Actor): Promise<Booking> {
    if (
      actor.role !== "PASSENGER" ||
      (request.customerId && request.customerId !== actor.uid)
    )
      throw new ForbiddenException(
        "Customers may create their own bookings only",
      );
    const passengers = request.passengers.map((p) => ({
      fullName: text(p.fullName, "passenger name"),
      ...(p.phone ? { phone: phone(p.phone) } : {}),
      ...(p.email ? { email: email(p.email) } : {}),
    }));
    const fingerprint = hash(
      JSON.stringify({
        quotationId: request.quotationId,
        paymentMethod: request.paymentMethod,
        passengers,
      }),
    );
    const requestRef = this.db
        .collection("booking_requests")
        .doc(hash(actor.uid + ":" + request.idempotencyKey)),
      quoteRef = this.db.collection("quotations").doc(request.quotationId);
    const bookingId = "BK-" + randomUUID(),
      code = String(randomInt(100000, 1000000)),
      salt = randomBytes(16).toString("hex");
    return this.db.runTransaction(async (tx) => {
      const [prior, quoteDoc] = await Promise.all([
        tx.get(requestRef),
        tx.get(quoteRef),
      ]);
      const quoteData = quoteDoc.data();
      if (!quoteData) throw new NotFoundException("Quote not found");
      const quote = parseQuotation(quoteData);
      if (quote.customerId !== actor.uid || !inScope(actor, quote))
        throw new NotFoundException("Quote not found");
      const priorId = prior.data()?.bookingId || quoteData.consumedBookingId;
      if (priorId) {
        if (
          (prior.data()?.fingerprint || quoteData.consumedFingerprint) !==
          fingerprint
        )
          throw new ConflictException(
            "The quote/request was already used for a different booking intent",
          );
        const existing = await tx.get(
          this.db.collection("bookings").doc(priorId),
        );
        if (!existing.exists)
          throw new ConflictException(
            "Reservation recovery failed; contact the control room",
          );
        return parseBooking(existing.data());
      }
      if (Date.parse(quote.expiresAt) <= Date.now())
        throw new ConflictException("The quote expired. Request a new quote.");
      if (passengers.length !== quote.input.passengerCount)
        throw new BadRequestException(
          "Passenger manifest must match the quoted count",
        );
      const booking = parseBooking({
        schemaVersion: "1",
        id: bookingId,
        referenceNumber: "PNG-DEMO-" + bookingId.slice(3, 15).toUpperCase(),
        organizationId: quote.organizationId,
        branchId: quote.branchId,
        airportId: quote.airportId,
        customerId: actor.uid,
        quotationId: quote.id,
        rateVersion: quote.rateVersion,
        input: quote.input,
        pricing: quote.pricing,
        status: "BOOKING_REQUESTED",
        payment: { status: "PENDING", method: request.paymentMethod },
        passengers,
        revision: 1,
        createdAt: now(),
        updatedAt: now(),
      });
      tx.create(this.db.collection("bookings").doc(booking.id), booking);
      tx.create(requestRef, {
        bookingId: booking.id,
        fingerprint,
        customerId: actor.uid,
      });
      tx.update(quoteRef, {
        consumedBookingId: booking.id,
        consumedFingerprint: fingerprint,
      });
      tx.create(this.db.collection("pickup_challenges").doc(booking.id), {
        code,
        salt,
        digest: hash(booking.id + ":" + salt + ":" + code),
        attempts: 0,
        used: false,
        expiresAt: new Date(
          Math.max(
            Date.now() + 30 * 60000,
            Date.parse(booking.input.pickupDateTime) + 60 * 60000,
          ),
        ).toISOString(),
      });
      this.event(tx, booking, actor, "BOOKING_REQUESTED");
      return booking;
    });
  }
  async getBooking(bookingId: string, actor?: Actor): Promise<Booking> {
    if (!actor) throw new ForbiddenException("Scoped actor required");
    id(bookingId);
    const doc = await this.db.collection("bookings").doc(bookingId).get();
    if (!doc.exists) throw new NotFoundException("Booking not found");
    const booking = parseBooking(doc.data());
    this.visible(actor, booking);
    return booking;
  }
  async list(
    actor: Actor,
    direction?: "INBOUND_AIRPORT_TO_CITY" | "OUTBOUND_CITY_TO_AIRPORT",
  ): Promise<Booking[]> {
    const rows = await this.db
      .collection("bookings")
      .where("organizationId", "==", actor.organizationId)
      .get();
    return rows.docs
      .map((d) => parseBooking(d.data()))
      .filter((b) => canReadBooking(actor, b))
      .filter((b) => !direction || b.input.direction === direction)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }
  async details(bookingId: string, actor: Actor) {
    const booking = await this.getBooking(bookingId, actor);
    let assignmentInfo = null;
    if (booking.dispatch) {
      const [driver, vehicle] = await Promise.all([
        this.db
          .collection("users")
          .doc(booking.dispatch.assignedDriverId)
          .get(),
        this.db
          .collection("vehicles")
          .doc(booking.dispatch.assignedVehicleId)
          .get(),
      ]);
      assignmentInfo = {
        driverName: driver.data()?.fullName ?? null,
        driverPhone: driver.data()?.phone ?? null,
        vehicleName: vehicle.data()?.makeModel ?? null,
        registrationPlate: vehicle.data()?.registrationPlate ?? null,
      };
    }
    const events = await this.db
      .collection("booking_events")
      .where("bookingId", "==", bookingId)
      .get();
    return {
      booking,
      assignmentInfo,
      events: events.docs
        .map((d) => d.data())
        .sort(
          (a, b) =>
            (a.revision ?? 0) - (b.revision ?? 0) ||
            (a.step ?? 0) - (b.step ?? 0) ||
            a.timestamp.localeCompare(b.timestamp),
        ),
    };
  }
  async pickupCredential(bookingId: string, actor: Actor) {
    const booking = await this.getBooking(bookingId, actor);
    if (actor.role !== "PASSENGER" || actor.uid !== booking.customerId)
      throw new ForbiddenException(
        "Only the customer may view their pickup credential",
      );
    const challenge = (
      await this.db.collection("pickup_challenges").doc(bookingId).get()
    ).data();
    if (
      terminal(booking.status) ||
      !challenge ||
      challenge.used ||
      Date.parse(challenge.expiresAt) <= Date.now() ||
      challenge.attempts >= 5
    )
      return { available: false };
    return {
      available: true,
      code: challenge.code,
      expiresAt: challenge.expiresAt,
    };
  }
  async assign(bookingId: string, value: unknown, actor: Actor) {
    staff(actor);
    id(bookingId);
    const data = body(value, ["driverId", "vehicleId", "expectedRevision"]),
      driverId = id(data.driverId, "driverId"),
      vehicleId = id(data.vehicleId, "vehicleId");
    const ref = this.db.collection("bookings").doc(bookingId);
    return this.db.runTransaction(async (tx) => {
      const [row, driverDoc, vehicleDoc, driverLock, vehicleLock] =
        await Promise.all([
          tx.get(ref),
          tx.get(this.db.collection("users").doc(driverId)),
          tx.get(this.db.collection("vehicles").doc(vehicleId)),
          tx.get(
            this.db.collection("resource_locks").doc("driver_" + driverId),
          ),
          tx.get(
            this.db.collection("resource_locks").doc("vehicle_" + vehicleId),
          ),
        ]);
      if (!row.exists) throw new NotFoundException("Booking not found");
      const booking = parseBooking(row.data());
      this.visible(actor, booking);
      if (
        ![
          "BOOKING_REQUESTED",
          "AVAILABILITY_CONFIRMED",
          "CONFIRMED",
          "DISPATCHED",
        ].includes(booking.status)
      )
        throw new ConflictException(
          "Reassignment is allowed only before departure",
        );
      if (
        booking.status === "DISPATCHED" &&
        booking.dispatch?.assignedDriverId === driverId &&
        booking.dispatch.assignedVehicleId === vehicleId
      )
        return booking;
      this.revision(booking, data.expectedRevision);
      const driver = driverDoc.data(),
        vehicle = vehicleDoc.data();
      if (
        !driver ||
        !vehicle ||
        !inScope(actor, driver) ||
        !inScope(actor, vehicle)
      )
        throw new NotFoundException("Driver or vehicle not found");
      if (
        driver.role !== "DRIVER" ||
        !driver.active ||
        driver.available !== true
      )
        throw new ConflictException("Choose an active driver who is on duty");
      if (
        vehicle.status !== "ACTIVE" ||
        vehicle.category !== booking.input.vehicleCategory ||
        vehicle.passengerCapacity < booking.input.passengerCount ||
        vehicle.luggageCapacity < booking.input.luggageCount
      )
        throw new ConflictException(
          "Vehicle is unavailable or incompatible with this booking",
        );
      for (const lock of [driverLock, vehicleLock])
        if (lock.data()?.bookingId && lock.data().bookingId !== bookingId)
          throw new ConflictException(
            "Driver or vehicle already has active work",
          );
      const from = booking.status;
      if (booking.dispatch) {
        if (booking.dispatch.assignedDriverId !== driverId)
          tx.delete(
            this.db
              .collection("resource_locks")
              .doc("driver_" + booking.dispatch.assignedDriverId),
          );
        if (booking.dispatch.assignedVehicleId !== vehicleId)
          tx.delete(
            this.db
              .collection("resource_locks")
              .doc("vehicle_" + booking.dispatch.assignedVehicleId),
          );
      }
      const scope = {
        organizationId: booking.organizationId,
        branchId: booking.branchId,
        airportId: booking.airportId,
        bookingId,
      };
      tx.set(this.db.collection("resource_locks").doc("driver_" + driverId), {
        ...scope,
        resourceId: driverId,
      });
      tx.set(this.db.collection("resource_locks").doc("vehicle_" + vehicleId), {
        ...scope,
        resourceId: vehicleId,
      });
      if (from !== "DISPATCHED") {
        booking.status = "AVAILABILITY_CONFIRMED";
        this.event(
          tx,
          { ...booking, revision: booking.revision + 1 },
          actor,
          "AVAILABILITY_CONFIRMED",
          from,
          1,
        );
        booking.status = "CONFIRMED";
        this.event(
          tx,
          { ...booking, revision: booking.revision + 1 },
          actor,
          "BOOKING_CONFIRMED",
          "AVAILABILITY_CONFIRMED",
          2,
        );
      }
      booking.dispatch = {
        assignedDriverId: driverId,
        assignedVehicleId: vehicleId,
      };
      booking.status = "DISPATCHED";
      tx.set(this.db.collection("dispatch_assignments").doc(bookingId), {
        ...scope,
        driverId,
        vehicleId,
        status: "PENDING_ACKNOWLEDGMENT",
        dispatchedBy: actor.uid,
        dispatchedAt: now(),
      });
      return this.save(
        tx,
        booking,
        actor,
        from === "DISPATCHED" ? "REASSIGNED" : "DISPATCHED",
        from,
      );
    });
  }
  async accept(bookingId: string, value: unknown, actor: Actor) {
    const data = body(value, ["expectedRevision", "inspection"]),
      inspection = body(data.inspection, [
        "seatbelts",
        "tyres",
        "fuel",
        "radio",
      ]);
    if (
      ["seatbelts", "tyres", "fuel", "radio"].some(
        (k) => inspection[k] !== true,
      )
    )
      throw new BadRequestException(
        "Complete all pre-trip checks before accepting",
      );
    return this.db.runTransaction(async (tx) => {
      const ref = this.db.collection("bookings").doc(id(bookingId)),
        row = await tx.get(ref);
      if (!row.exists) throw new NotFoundException("Booking not found");
      const b = parseBooking(row.data());
      this.visible(actor, b);
      if (actor.role !== "DRIVER" || b.dispatch?.assignedDriverId !== actor.uid)
        throw new ForbiddenException("Assigned driver required");
      if (b.status !== "DISPATCHED")
        throw new ConflictException(
          "Assignment is no longer awaiting acceptance",
        );
      if (b.dispatch.acceptedAt) return b;
      this.revision(b, data.expectedRevision);
      b.dispatch.acceptedAt = now();
      tx.set(
        this.db.collection("dispatch_assignments").doc(bookingId),
        {
          status: "ACCEPTED",
          driverAcknowledgedAt: b.dispatch.acceptedAt,
          inspection,
        },
        { merge: true },
      );
      return this.save(tx, b, actor, "DRIVER_ACCEPTED", b.status);
    });
  }
  async status(bookingId: string, value: unknown, actor: Actor) {
    const data = body(value, ["status", "expectedRevision"]),
      target = text(data.status, "status") as Status;
    return this.db.runTransaction(async (tx) => {
      const ref = this.db.collection("bookings").doc(id(bookingId)),
        row = await tx.get(ref);
      if (!row.exists) throw new NotFoundException("Booking not found");
      const b = parseBooking(row.data());
      this.visible(actor, b);
      const role = actor.role === "SUPER_ADMIN" ? "SUPERVISOR" : actor.role;
      if (target === "CANCELLED") {
        if (!["PASSENGER", "DISPATCHER", "SUPERVISOR"].includes(role))
          throw new ForbiddenException("Cancellation is not permitted");
      } else if (target === "CLOSED") {
        if (role !== "SUPERVISOR")
          throw new ForbiddenException("Supervisor required");
      } else if (
        role !== "DRIVER" ||
        b.dispatch?.assignedDriverId !== actor.uid
      )
        throw new ForbiddenException("Assigned driver required");
      if (b.status === target) return b;
      this.revision(b, data.expectedRevision);
      if (!canTransition(role, b.status, target, b.input.direction))
        throw new ConflictException("This status transition is not permitted");
      if (target === "DRIVER_EN_ROUTE" && !b.dispatch?.acceptedAt)
        throw new ConflictException(
          "Accept the assignment and inspection first",
        );
      const from = b.status;
      b.status = target;
      if (terminal(target) && !terminal(from) && b.dispatch) {
        tx.delete(
          this.db
            .collection("resource_locks")
            .doc("driver_" + b.dispatch.assignedDriverId),
        );
        tx.delete(
          this.db
            .collection("resource_locks")
            .doc("vehicle_" + b.dispatch.assignedVehicleId),
        );
        tx.set(
          this.db.collection("dispatch_assignments").doc(bookingId),
          { status: target, updatedAt: now() },
          { merge: true },
        );
      }
      return this.save(tx, b, actor, target, from);
    });
  }
  async verify(bookingId: string, value: unknown, actor: Actor) {
    const data = body(value, ["code", "expectedRevision"]);
    if (typeof data.code !== "string" || !/^\d{6}$/.test(data.code))
      throw new BadRequestException("Enter the six-digit pickup code");
    const result = await this.db.runTransaction(async (tx) => {
      const ref = this.db.collection("bookings").doc(id(bookingId)),
        challengeRef = this.db.collection("pickup_challenges").doc(bookingId);
      const [row, challengeRow] = await Promise.all([
        tx.get(ref),
        tx.get(challengeRef),
      ]);
      if (!row.exists) throw new NotFoundException("Booking not found");
      const b = parseBooking(row.data());
      this.visible(actor, b);
      if (actor.role !== "DRIVER" || b.dispatch?.assignedDriverId !== actor.uid)
        throw new ForbiddenException("Assigned driver required");
      this.revision(b, data.expectedRevision);
      const c = challengeRow.data();
      if (
        b.status !==
          (b.input.direction === "OUTBOUND_CITY_TO_AIRPORT"
            ? "AT_PICKUP"
            : "AT_AIRPORT") ||
        !c ||
        c.used
      )
        throw new ConflictException(
          "Pickup verification is not available at this stage",
        );
      if (Date.parse(c.expiresAt) <= Date.now())
        throw new ConflictException(
          "Pickup code expired. Ask the supervisor to reissue it.",
        );
      if (c.attempts >= 5) return { error: 429 };
      const supplied = hash(bookingId + ":" + c.salt + ":" + data.code),
        expected = String(c.digest);
      if (
        expected.length !== supplied.length ||
        !timingSafeEqual(Buffer.from(expected), Buffer.from(supplied))
      ) {
        tx.update(challengeRef, { attempts: c.attempts + 1 });
        return { error: c.attempts + 1 >= 5 ? 429 : 400 };
      }
      tx.update(challengeRef, {
        used: true,
        verifiedAt: now(),
        verifiedBy: actor.uid,
        code: null,
      });
      const from = b.status;
      b.status = "PASSENGER_VERIFIED";
      return { booking: this.save(tx, b, actor, "PASSENGER_VERIFIED", from) };
    });
    if (result.error)
      throw new HttpException(
        result.error === 429
          ? "Pickup code locked after five failed attempts"
          : "Incorrect pickup code",
        result.error,
      );
    return result.booking;
  }
  async resetPickup(bookingId: string, value: unknown, actor: Actor) {
    staff(actor, true);
    const data = body(value, ["reason", "expectedRevision"]),
      reason = text(data.reason, "reason", 500);
    return this.db.runTransaction(async (tx) => {
      const row = await tx.get(
        this.db.collection("bookings").doc(id(bookingId)),
      );
      if (!row.exists) throw new NotFoundException("Booking not found");
      const b = parseBooking(row.data());
      this.visible(actor, b);
      this.revision(b, data.expectedRevision);
      if (
        b.status !==
        (b.input.direction === "OUTBOUND_CITY_TO_AIRPORT"
          ? "AT_PICKUP"
          : "AT_AIRPORT")
      )
        throw new ConflictException(
          "Reissue is permitted only before passenger pickup",
        );
      const previous = (
        await tx.get(this.db.collection("pickup_challenges").doc(bookingId))
      ).data();
      let code: string;
      do {
        code = String(randomInt(100000, 1000000));
      } while (code === previous?.code);
      const salt = randomBytes(16).toString("hex");
      tx.set(this.db.collection("pickup_challenges").doc(bookingId), {
        code,
        salt,
        digest: hash(bookingId + ":" + salt + ":" + code),
        attempts: 0,
        used: false,
        expiresAt: new Date(Date.now() + 30 * 60000).toISOString(),
      });
      return this.save(
        tx,
        b,
        actor,
        "PICKUP_CODE_REISSUED: " + reason,
        b.status,
      );
    });
  }
}

import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import { FirebaseService } from "../../firebase/firebase.service";
import { VehicleCategoryEnum } from "../quotations/dto/create-quote.dto";

export interface VehicleEntity {
  id: string;
  registrationPlate: string;
  make: string;
  model: string;
  year: number;
  category: VehicleCategoryEnum;
  passengerCapacity: number;
  luggageCapacity: number;
  ownershipType: "COMPANY_OWNED" | "PARTNER_OPERATOR";
  partnerOperatorId?: string;
  branchId: string;
  roadworthyExpiry: string;
  insuranceExpiry: string;
  status: "ACTIVE" | "MAINTENANCE" | "SUSPENDED";
  isArmored: boolean;
  armorLevel?: "B4" | "B6" | "B7";
}

export interface DriverEntity {
  id: string;
  fullName: string;
  phone: string;
  email: string;
  licenseNumber: string;
  licenseClass: string;
  licenseExpiry: string;
  medicalCertExpiry: string;
  branchId: string;
  ownershipType: "COMPANY_EMPLOYED" | "PARTNER_OPERATOR";
  partnerOperatorId?: string;
  status: "AVAILABLE" | "ON_DUTY" | "REST_PERIOD" | "SUSPENDED";
  rating: number;
  completedTripsCount: number;
}

export interface SecurityPersonnelEntity {
  id: string;
  fullName: string;
  callsign: string;
  phone: string;
  rpngcPermitNumber: string; // Royal PNG Constabulary permit
  firearmPermitNumber: string;
  firearmPermitExpiry: string;
  tacticalLevel: "STANDARD_GUARD" | "ARMED_ESCORT" | "CLOSE_PROTECTION_OFFICER";
  branchId: string;
  status: "AVAILABLE" | "ASSIGNED" | "REST" | "SUSPENDED";
  equipmentAssigned: string[];
}

import { Actor } from "@png-transfer/types";
import { BadRequestException, ConflictException } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import {
  body,
  text,
  id,
  staff,
  inScope,
  DEMO_SCOPE,
  now,
  unavailable,
  localScope,
} from "../../common/workflow";
import { DEMO_CATEGORIES } from "../../config/demo";
export interface VehicleRecord {
  id: string;
  organizationId: string;
  branchId: string;
  airportId: string;
  makeModel: string;
  registrationPlate: string;
  category: string;
  passengerCapacity: number;
  luggageCapacity: number;
  status: "ACTIVE" | "MAINTENANCE" | "INACTIVE";
  createdAt: string;
}
@Injectable()
export class ResourcesService {
  constructor(private readonly firebaseService: FirebaseService) {}
  async vehicles(actor: Actor) {
    staff(actor);
    const db = this.firebaseService.firestore;
    const [rows, locks] = await Promise.all([
      db
        .collection("vehicles")
        .where("organizationId", "==", actor.organizationId)
        .get(),
      db
        .collection("resource_locks")
        .where("organizationId", "==", actor.organizationId)
        .get(),
    ]);
    const busy = new Map(
      locks.docs
        .filter((d) => d.data().bookingId)
        .map((d) => [d.data().resourceId, d.data().bookingId]),
    );
    return rows.docs
      .map((d) => d.data() as VehicleRecord)
      .filter((v) => inScope(actor, v))
      .map((v) => ({
        ...v,
        available: v.status === "ACTIVE" && !busy.has(v.id),
        activeBookingId: busy.get(v.id) ?? null,
      }));
  }
  async drivers(actor: Actor) {
    if (actor.role !== "DRIVER") staff(actor);
    const db = this.firebaseService.firestore;
    const [users, locks, jobs] = await Promise.all([
      db
        .collection("users")
        .where("organizationId", "==", actor.organizationId)
        .get(),
      db
        .collection("resource_locks")
        .where("organizationId", "==", actor.organizationId)
        .get(),
      db
        .collection("bookings")
        .where("organizationId", "==", actor.organizationId)
        .get(),
    ]);
    return users.docs
      .map((d) => d.data())
      .filter(
        (u) =>
          u.role === "DRIVER" &&
          inScope(actor, u) &&
          (actor.role !== "DRIVER" || u.uid === actor.uid),
      )
      .map((u) => {
        const active = locks.docs
          .find((d) => d.data().resourceId === u.uid && d.data().bookingId)
          ?.data().bookingId;
        return {
          id: u.uid,
          fullName: u.fullName,
          phone: u.phone ?? null,
          active: u.active,
          onDuty: u.available === true,
          available: u.active === true && u.available === true && !active,
          activeBookingId: active ?? null,
          completedTrips: jobs.docs.filter(
            (d) =>
              d.data().dispatch?.assignedDriverId === u.uid &&
              ["COMPLETED", "CLOSED"].includes(d.data().status),
          ).length,
        };
      });
  }
  async createVehicle(actor: Actor, value: unknown) {
    staff(actor, true);
    const scope = localScope(actor);
    const data = body(value, ["makeModel", "registrationPlate", "category"]),
      category = DEMO_CATEGORIES.find((c) => c.id === data.category);
    if (!category)
      throw new BadRequestException("Choose a configured category");
    const vehicle: VehicleRecord = {
      id: "veh_" + randomUUID(),
      ...scope,
      makeModel: text(data.makeModel, "vehicle name"),
      registrationPlate: text(
        data.registrationPlate,
        "plate",
        30,
      ).toUpperCase(),
      category: category.id,
      passengerCapacity: category.passengerCapacity,
      luggageCapacity: category.luggageCapacity,
      status: "ACTIVE",
      createdAt: now(),
    };
    const db = this.firebaseService.firestore,
      plate = db
        .collection("vehicle_plates")
        .doc(
          encodeURIComponent(
            actor.organizationId + ":" + vehicle.registrationPlate,
          ),
        );
    await db.runTransaction(async (tx) => {
      if ((await tx.get(plate)).exists)
        throw new ConflictException("Plate is already registered");
      tx.create(db.collection("vehicles").doc(vehicle.id), vehicle);
      tx.create(plate, { vehicleId: vehicle.id });
      tx.create(db.collection("audit_logs").doc(), {
        ...scope,
        actorId: actor.uid,
        action: "VEHICLE_CREATED",
        resourceId: vehicle.id,
        timestamp: now(),
      });
    });
    return vehicle;
  }
  async updateVehicle(actor: Actor, vehicleId: string, value: unknown) {
    staff(actor, true);
    id(vehicleId);
    const data = body(value, ["makeModel", "status"]),
      db = this.firebaseService.firestore,
      ref = db.collection("vehicles").doc(vehicleId);
    return db.runTransaction(async (tx) => {
      const [row, lock] = await Promise.all([
        tx.get(ref),
        tx.get(db.collection("resource_locks").doc("vehicle_" + vehicleId)),
      ]);
      const vehicle = row.data() as VehicleRecord;
      if (!vehicle || !inScope(actor, vehicle))
        throw new NotFoundException("Vehicle not found");
      if (lock.data()?.bookingId)
        throw new ConflictException(
          "Finish or reassign the active trip before editing this vehicle",
        );
      const changes: Partial<VehicleRecord> = {};
      if (data.makeModel !== undefined)
        changes.makeModel = text(data.makeModel, "vehicle name");
      if (data.status !== undefined) {
        if (
          !["ACTIVE", "MAINTENANCE", "INACTIVE"].includes(data.status as string)
        )
          throw new BadRequestException("Invalid vehicle status");
        changes.status = data.status as VehicleRecord["status"];
      }
      tx.update(ref, changes);
      tx.create(db.collection("audit_logs").doc(), {
        organizationId: vehicle.organizationId,
        branchId: vehicle.branchId,
        airportId: vehicle.airportId,
        actorId: actor.uid,
        action: "VEHICLE_UPDATED",
        resourceId: vehicleId,
        timestamp: now(),
      });
      return { ...vehicle, ...changes };
    });
  }
  async duty(actor: Actor, driverId: string, value: unknown) {
    if (actor.role !== "DRIVER") staff(actor, true);
    else if (actor.uid !== driverId)
      throw new NotFoundException("Driver not found");
    id(driverId);
    const data = body(value, ["available"]);
    if (typeof data.available !== "boolean")
      throw new BadRequestException("available must be boolean");
    const db = this.firebaseService.firestore,
      ref = db.collection("users").doc(driverId);
    return db.runTransaction(async (tx) => {
      const [row, lock] = await Promise.all([
          tx.get(ref),
          tx.get(db.collection("resource_locks").doc("driver_" + driverId)),
        ]),
        user = row.data();
      if (
        !user ||
        user.role !== "DRIVER" ||
        !inScope(actor, user as VehicleRecord)
      )
        throw new NotFoundException("Driver not found");
      if (lock.data()?.bookingId)
        throw new ConflictException("Driver has active work");
      tx.update(ref, { available: data.available });
      tx.create(db.collection("audit_logs").doc(), {
        organizationId: user.organizationId,
        branchId: user.branchId,
        airportId: user.airportId,
        actorId: actor.uid,
        action: data.available ? "DRIVER_ON_DUTY" : "DRIVER_OFF_DUTY",
        resourceId: driverId,
        timestamp: now(),
      });
      return { available: data.available };
    });
  }
  // Legacy compliance/time-window adapters are unavailable; no sample fallback.
  async listVehicles(
    _category?: VehicleCategoryEnum,
  ): Promise<VehicleEntity[]> {
    return unavailable("Legacy resource adapter is not active");
  }
  async listDrivers(): Promise<DriverEntity[]> {
    return unavailable("Legacy resource adapter is not active");
  }
  async listSecurityPersonnel(): Promise<SecurityPersonnelEntity[]> {
    return unavailable("Security staffing is not configured");
  }
  async findVehicleById(_id: string): Promise<VehicleEntity> {
    return unavailable("Use scoped fleet records");
  }
  async findDriverById(_id: string): Promise<DriverEntity> {
    return unavailable("Use scoped driver records");
  }
  async findGuardById(_id: string): Promise<SecurityPersonnelEntity> {
    return unavailable("Security staffing is not configured");
  }
}

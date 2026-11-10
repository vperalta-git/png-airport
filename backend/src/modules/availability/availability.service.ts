import { Injectable, Logger, ConflictException } from '@nestjs/common';
import { FirebaseService } from '../../firebase/firebase.service';
import { ResourcesService } from '../resources/resources.service';
import { VehicleCategoryEnum, SecurityEscortTypeEnum } from '../quotations/dto/create-quote.dto';

export interface ResourceReservation {
  id: string;
  resourceId: string;
  resourceType: 'VEHICLE' | 'DRIVER' | 'SECURITY';
  bookingId: string;
  startTime: string; // ISO
  endTime: string; // ISO
  status: 'HELD' | 'CONFIRMED' | 'RELEASED' | 'EXPIRED';
  expiresAt: string; // ISO - for temporary lease holds
  createdAt: string;
}

export interface AvailabilityCheckResult {
  isAvailable: boolean;
  vehicle?: { id: string; make: string; model: string; plate: string };
  driver?: { id: string; fullName: string; phone: string };
  security?: { id: string; fullName: string; callsign: string };
  conflicts: string[];
  suggestedAlternatives?: string[];
}

@Injectable()
export class AvailabilityService {
  private readonly logger = new Logger(AvailabilityService.name);
  private readonly reservationsCollection = 'resource_reservations';

  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly resourcesService: ResourcesService,
  ) {}

  /**
   * Calculates estimated trip window: pickup time to estimated completion + 45 minute buffer
   */
  calculateTripWindow(pickupDateTime: string, estimatedDistanceKm: number = 42) {
    const start = new Date(pickupDateTime);
    // Typical PNG highway transit speed ~45 km/h + terminal waiting
    const transitMinutes = Math.max(60, Math.round((estimatedDistanceKm / 45) * 60) + 45);
    const end = new Date(start.getTime() + transitMinutes * 60 * 1000);
    return { startTime: start.toISOString(), endTime: end.toISOString() };
  }

  /**
   * Checks if a specific resource is booked/held during [startTime, endTime]
   */
  async isResourceBusy(
    resourceId: string,
    startTime: string,
    endTime: string,
    excludeBookingId?: string,
  ): Promise<boolean> {
    const reqStart = new Date(startTime).getTime();
    const reqEnd = new Date(endTime).getTime();
    const now = Date.now();

    try {
      const snapshot = await this.firebaseService.firestore
        .collection(this.reservationsCollection)
        .where('resourceId', '==', resourceId)
        .where('status', 'in', ['HELD', 'CONFIRMED'])
        .get();

      for (const doc of snapshot.docs) {
        const data = doc.data() as ResourceReservation;
        if (excludeBookingId && data.bookingId === excludeBookingId) continue;

        // If it's only a temporary hold and expired, ignore it
        if (data.status === 'HELD' && new Date(data.expiresAt).getTime() < now) {
          continue;
        }

        const resStart = new Date(data.startTime).getTime();
        const resEnd = new Date(data.endTime).getTime();

        // Overlap condition: (StartA < EndB) and (EndA > StartB)
        if (reqStart < resEnd && reqEnd > resStart) {
          return true; // Conflict detected
        }
      }
    } catch (e) {
      this.logger.warn(`Firestore check error: ${e.message}`);
    }

    return false;
  }

  /**
   * Evaluates availability of suitable vehicle, driver, and security personnel
   */
  async checkAvailability(
    category: VehicleCategoryEnum,
    securityType: SecurityEscortTypeEnum,
    pickupDateTime: string,
    estimatedDistanceKm: number = 42,
  ): Promise<AvailabilityCheckResult> {
    const { startTime, endTime } = this.calculateTripWindow(pickupDateTime, estimatedDistanceKm);
    const conflicts: string[] = [];

    // 1. Find suitable vehicle
    const candidateVehicles = await this.resourcesService.listVehicles(category);
    let selectedVehicle = null;
    for (const veh of candidateVehicles) {
      const busy = await this.isResourceBusy(veh.id, startTime, endTime);
      if (!busy) {
        selectedVehicle = veh;
        break;
      }
    }

    if (!selectedVehicle) {
      conflicts.push(`No available ${category} vehicles for the requested time slot`);
    }

    // 2. Find available driver
    const candidateDrivers = await this.resourcesService.listDrivers();
    let selectedDriver = null;
    for (const drv of candidateDrivers) {
      const busy = await this.isResourceBusy(drv.id, startTime, endTime);
      if (!busy) {
        selectedDriver = drv;
        break;
      }
    }

    if (!selectedDriver) {
      conflicts.push('No available qualified drivers for the requested time slot');
    }

    // 3. Find security personnel if requested
    let selectedSecurity = null;
    if (securityType !== SecurityEscortTypeEnum.NONE) {
      const candidateGuards = await this.resourcesService.listSecurityPersonnel();
      for (const guard of candidateGuards) {
        const busy = await this.isResourceBusy(guard.id, startTime, endTime);
        if (!busy) {
          selectedSecurity = guard;
          break;
        }
      }
      if (!selectedSecurity) {
        conflicts.push(`No qualified armed security personnel available for ${securityType}`);
      }
    }

    const isAvailable = conflicts.length === 0;

    return {
      isAvailable,
      vehicle: selectedVehicle
        ? {
            id: selectedVehicle.id,
            make: selectedVehicle.make,
            model: selectedVehicle.model,
            plate: selectedVehicle.registrationPlate,
          }
        : undefined,
      driver: selectedDriver
        ? {
            id: selectedDriver.id,
            fullName: selectedDriver.fullName,
            phone: selectedDriver.phone,
          }
        : undefined,
      security: selectedSecurity
        ? {
            id: selectedSecurity.id,
            fullName: selectedSecurity.fullName,
            callsign: selectedSecurity.callsign,
          }
        : undefined,
      conflicts,
      suggestedAlternatives: isAvailable
        ? []
        : ['Shift pickup time by +/- 60 minutes', 'Select alternative vehicle category'],
    };
  }

  /**
   * Atomically locks resources via Firestore transaction to prevent race conditions & double-booking
   */
  async lockResourcesInTransaction(
    bookingId: string,
    resourceIds: string[],
    startTime: string,
    endTime: string,
    status: 'HELD' | 'CONFIRMED' = 'CONFIRMED',
  ): Promise<ResourceReservation[]> {
    const db = this.firebaseService.firestore;
    const now = new Date();
    const holdExpiresAt = new Date(now.getTime() + 15 * 60 * 1000).toISOString(); // 15 mins hold

    const reservationsToCreate: ResourceReservation[] = [];

    // Run within atomic Firestore transaction
    await db.runTransaction(async (transaction) => {
      for (const resId of resourceIds) {
        const busy = await this.isResourceBusy(resId, startTime, endTime, bookingId);
        if (busy) {
          throw new ConflictException(
            `Resource conflict: Resource '${resId}' is already reserved for this time slot`,
          );
        }

        const reservationId = `RES-${bookingId}-${resId}`;
        const ref = db.collection(this.reservationsCollection).doc(reservationId);

        const reservation: ResourceReservation = {
          id: reservationId,
          resourceId: resId,
          resourceType: resId.startsWith('veh_')
            ? 'VEHICLE'
            : resId.startsWith('driver_')
            ? 'DRIVER'
            : 'SECURITY',
          bookingId,
          startTime,
          endTime,
          status,
          expiresAt: holdExpiresAt,
          createdAt: now.toISOString(),
        };

        transaction.set(ref, reservation);
        reservationsToCreate.push(reservation);
      }
    });

    this.logger.log(`Successfully locked resources for booking ${bookingId}: ${resourceIds.join(', ')}`);
    return reservationsToCreate;
  }

  /**
   * Release resource reservations when a booking is completed or cancelled
   */
  async releaseResources(bookingId: string): Promise<void> {
    try {
      const snapshot = await this.firebaseService.firestore
        .collection(this.reservationsCollection)
        .where('bookingId', '==', bookingId)
        .get();

      const batch = this.firebaseService.firestore.batch();
      snapshot.docs.forEach((doc) => {
        batch.update((doc as any).ref, { status: 'RELEASED', releasedAt: new Date().toISOString() });
      });
      await batch.commit();
      this.logger.log(`Released reservations for booking ${bookingId}`);
    } catch (e) {
      this.logger.error(`Error releasing reservations for ${bookingId}: ${e.message}`);
    }
  }
}


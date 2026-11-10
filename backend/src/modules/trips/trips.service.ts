import { Injectable } from "@nestjs/common";
import { Actor } from "@png-transfer/types";
import { BookingsService } from "../bookings/bookings.service";
export interface GpsCoordinate {
  latitude: number;
  longitude: number;
  speedKmh?: number;
  heading?: number;
  timestamp: string;
}
export interface ElectronicPodDto {
  recipientName: string;
  odometerEndKm: number;
  dropoffLocation: GpsCoordinate;
  passengerSignatureBase64?: string;
  notes?: string;
}
@Injectable()
export class TripsService {
  constructor(private readonly bookings: BookingsService) {}
  startTransfer(id: string, value: Record<string, unknown>, actor: Actor) {
    return this.bookings.status(
      id,
      { ...value, status: "TRANSFER_IN_PROGRESS" },
      actor,
    );
  }
  completeTrip(id: string, value: Record<string, unknown>, actor: Actor) {
    return this.bookings.status(id, { ...value, status: "COMPLETED" }, actor);
  }
}

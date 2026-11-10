import { Injectable } from "@nestjs/common";
import { BookingStatus } from "../bookings/bookings.service";
import { unavailable } from "../../common/workflow";
export interface SyncEventPayload {
  eventId: string;
  deviceId: string;
  userId: string;
  bookingId: string;
  eventType: string;
  clientTimestamp: string;
  payload: Record<string, unknown>;
  expectedBookingStatus?: BookingStatus;
}
export interface SyncBatchResult {
  processedCount: number;
  results: {
    eventId: string;
    status: "APPLIED" | "DUPLICATE_IGNORED" | "REJECTED";
    message: string;
  }[];
}
@Injectable()
export class OfflineSyncService {
  async processSyncBatch(
    _events: SyncEventPayload[],
  ): Promise<SyncBatchResult> {
    return unavailable(
      "Durable offline synchronization is not configured; reconnect before changing trip status.",
    );
  }
}

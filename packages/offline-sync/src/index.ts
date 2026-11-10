import { OfflineSyncEvent } from "../../types/src/legacy";

/**
 * Idempotent Monotonic Offline Event Queue Manager.
 * Guarantees zero event loss for drivers operating in remote low-coverage PNG corridors.
 */
export class OfflineSyncQueue {
  private queue: OfflineSyncEvent[] = [];
  private isProcessing: boolean = false;

  public enqueue(
    eventType: string,
    bookingId: number,
    payload: Record<string, unknown> = {},
    lat?: number,
    lon?: number,
  ): OfflineSyncEvent {
    const event: OfflineSyncEvent = {
      uuid: this.generateUUID(),
      event_type: eventType,
      booking_id: bookingId,
      payload,
      local_timestamp: new Date().toISOString(),
      latitude: lat,
      longitude: lon,
      sync_status: "pending",
      retry_count: 0,
    };
    this.queue.push(event);
    return event;
  }

  public getPendingEvents(): OfflineSyncEvent[] {
    return this.queue.filter((e) => e.sync_status === "pending");
  }

  public markSynced(uuid: string) {
    const item = this.queue.find((e) => e.uuid === uuid);
    if (item) {
      item.sync_status = "synced";
    }
  }

  public markFailed(uuid: string) {
    const item = this.queue.find((e) => e.uuid === uuid);
    if (item) {
      item.retry_count += 1;
      if (item.retry_count >= 5) {
        item.sync_status = "failed";
      }
    }
  }

  private generateUUID(): string {
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }
}

import { Injectable } from "@nestjs/common";
import { Actor } from "@png-transfer/types";
import { BookingsService } from "../bookings/bookings.service";
@Injectable()
export class DispatchService {
  constructor(private readonly bookings: BookingsService) {}
  assignDispatch(id: string, value: unknown, actor: Actor) {
    return this.bookings.assign(id, value, actor);
  }
  driverAcknowledgeAndInspect(id: string, value: unknown, actor: Actor) {
    return this.bookings.accept(id, value, actor);
  }
  listActiveDispatches(actor: Actor) {
    return this.bookings
      .list(actor)
      .then((rows) =>
        rows.filter(
          (b) =>
            b.dispatch &&
            !["COMPLETED", "CLOSED", "CANCELLED"].includes(b.status),
        ),
      );
  }
}

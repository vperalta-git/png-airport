import { Injectable } from "@nestjs/common";
import { Actor } from "@png-transfer/types";
import { FirebaseService } from "../../firebase/firebase.service";
import { BookingsService } from "../bookings/bookings.service";
import { ResourcesService } from "../resources/resources.service";
import { staff, inScope } from "../../common/workflow";
@Injectable()
export class ReportsService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly bookings: BookingsService,
    private readonly resources: ResourcesService,
  ) {}
  async summary(actor: Actor) {
    staff(actor);
    const [jobs, drivers, vehicles] = await Promise.all([
      this.bookings.list(actor),
      this.resources.drivers(actor),
      this.resources.vehicles(actor),
    ]);
    return {
      bookings: jobs.length,
      awaitingAssignment: jobs.filter(
        (b) =>
          !b.dispatch &&
          !["CANCELLED", "COMPLETED", "CLOSED"].includes(b.status),
      ).length,
      activeTrips: jobs.filter(
        (b) =>
          b.dispatch &&
          !["CANCELLED", "COMPLETED", "CLOSED"].includes(b.status),
      ).length,
      completedTrips: jobs.filter((b) =>
        ["COMPLETED", "CLOSED"].includes(b.status),
      ).length,
      cancelledTrips: jobs.filter((b) => b.status === "CANCELLED").length,
      pendingPayments: jobs.filter((b) => b.payment.status === "PENDING")
        .length,
      verifiedPayments: jobs.filter((b) => b.payment.status === "PAID").length,
      availableDrivers: drivers.filter((d) => d.available).length,
      availableVehicles: vehicles.filter((v) => v.available).length,
    };
  }
  async audit(actor: Actor) {
    staff(actor, true);
    const rows = await this.firebase.firestore
      .collection("audit_logs")
      .where("organizationId", "==", actor.organizationId)
      .get();
    return rows.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((r: any) => inScope(actor, r))
      .sort((a: any, b: any) => b.timestamp.localeCompare(a.timestamp))
      .slice(0, 200);
  }
}

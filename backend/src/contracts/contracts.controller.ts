import { Controller, Get } from "@nestjs/common";
import {
  CONTRACT_VERSION,
  ROLES,
  BOOKING_STATUSES,
  PAYMENT_STATUSES,
  ROLE_PERMISSIONS,
} from "@png-transfer/types";

@Controller("contracts")
export class ContractsController {
  @Get()
  getContract() {
    return {
      schemaVersion: CONTRACT_VERSION,
      roles: ROLES,
      rolePermissions: ROLE_PERMISSIONS,
      bookingStatuses: BOOKING_STATUSES,
      paymentStatuses: PAYMENT_STATUSES,
      country: "PG",
      currency: "PGK",
      timezone: "Pacific/Port_Moresby",
      pricingConfigured: process.env.AEROTRANS_DEMO_RATES === 'true',
      demoMode: true,
      operationalWorkflowsEnabled: true,
    };
  }
}

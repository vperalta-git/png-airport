import { Controller, Get } from "@nestjs/common";
import { runtimeIdentity } from "./config/runtime-environment";
@Controller("health")
export class HealthController {
  @Get()
  checkHealth() {
    return {
      status: "UP",
      ...runtimeIdentity(),
      country: "PG",
      currency: "PGK",
      timezone: "Pacific/Port_Moresby",
      contractVersion: "1",
      operationalWorkflowsEnabled: true,
    };
  }
}

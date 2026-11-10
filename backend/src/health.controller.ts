import { Controller, Get } from "@nestjs/common";
import { LOCAL_PROJECT_ID } from "./config/local-environment";
@Controller("health")
export class HealthController {
  @Get()
  checkHealth() {
    return {
      status: "UP",
      environment: "local",
      projectId: LOCAL_PROJECT_ID,
      country: "PG",
      currency: "PGK",
      timezone: "Pacific/Port_Moresby",
      contractVersion: "1",
      operationalWorkflowsEnabled: true,
    };
  }
}

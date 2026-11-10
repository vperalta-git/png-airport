import { Controller, Post, Param, Body } from "@nestjs/common";
import { TripsService } from "./trips.service";
import { AuthenticatedUser } from "../../common/guards/auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Workflow, body } from "../../common/workflow";
@Controller("trips")
@Workflow()
export class TripsController {
  constructor(private readonly trips: TripsService) {}
  @Post(":id/start") start(
    @Param("id") id: string,
    @Body() v: unknown,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.trips.startTransfer(id, body(v, ["expectedRevision"]), a);
  }
  @Post(":id/complete") complete(
    @Param("id") id: string,
    @Body() v: unknown,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.trips.completeTrip(id, body(v, ["expectedRevision"]), a);
  }
}

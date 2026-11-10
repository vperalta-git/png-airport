import { Controller, Get, Post, Patch, Param, Body } from "@nestjs/common";
import { ResourcesService } from "./resources.service";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { AuthenticatedUser } from "../../common/guards/auth.guard";
import { Workflow } from "../../common/workflow";
@Controller("resources")
@Workflow()
export class ResourcesController {
  constructor(private readonly resources: ResourcesService) {}
  @Get("vehicles") vehicles(@CurrentUser() a: AuthenticatedUser) {
    return this.resources.vehicles(a);
  }
  @Post("vehicles") create(
    @CurrentUser() a: AuthenticatedUser,
    @Body() b: unknown,
  ) {
    return this.resources.createVehicle(a, b);
  }
  @Patch("vehicles/:id") update(
    @CurrentUser() a: AuthenticatedUser,
    @Param("id") id: string,
    @Body() b: unknown,
  ) {
    return this.resources.updateVehicle(a, id, b);
  }
  @Get("drivers") drivers(@CurrentUser() a: AuthenticatedUser) {
    return this.resources.drivers(a);
  }
  @Patch("drivers/:id") duty(
    @CurrentUser() a: AuthenticatedUser,
    @Param("id") id: string,
    @Body() b: unknown,
  ) {
    return this.resources.duty(a, id, b);
  }
}

import { Controller, Post, Get, Param, Body } from "@nestjs/common";
import { DispatchService } from "./dispatch.service";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { AuthenticatedUser } from "../../common/guards/auth.guard";
import { Workflow } from "../../common/workflow";
@Controller("dispatch")
@Workflow()
export class DispatchController {
  constructor(private readonly dispatch: DispatchService) {}
  @Post(":id/assign") assign(
    @Param("id") id: string,
    @Body() v: unknown,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.dispatch.assignDispatch(id, v, a);
  }
  @Post(":id/acknowledge") accept(
    @Param("id") id: string,
    @Body() v: unknown,
    @CurrentUser() a: AuthenticatedUser,
  ) {
    return this.dispatch.driverAcknowledgeAndInspect(id, v, a);
  }
  @Get("active") list(@CurrentUser() a: AuthenticatedUser) {
    return this.dispatch.listActiveDispatches(a);
  }
}

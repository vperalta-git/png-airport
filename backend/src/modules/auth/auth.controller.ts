import { Controller, Post, Get, Patch, Param, Body } from "@nestjs/common";
import { AuthService } from "./auth.service";
import { AuthenticatedUser } from "../../common/guards/auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Roles } from "../../common/decorators/roles.decorator";
import { Workflow, PublicWorkflow, unavailable } from "../../common/workflow";
@Controller("auth")
@Workflow()
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Post("register") @PublicWorkflow() register(@Body() value: unknown) {
    return this.auth.register(value);
  }
  @Post("login") @PublicWorkflow() login() {
    return unavailable(
      "Use Firebase Auth to sign in; simulated sessions are not supported.",
    );
  }
  @Get("me") me(@CurrentUser() actor: AuthenticatedUser) {
    return this.auth.me(actor);
  }
  @Post("logout") logout(@CurrentUser() actor: AuthenticatedUser) {
    return this.auth.logout(actor);
  }
}
@Controller("users")
@Workflow()
@Roles("SUPERVISOR", "SUPER_ADMIN")
export class UsersController {
  constructor(private readonly auth: AuthService) {}
  @Get() list(@CurrentUser() actor: AuthenticatedUser) {
    return this.auth.list(actor);
  }
  @Post() create(
    @CurrentUser() actor: AuthenticatedUser,
    @Body() value: unknown,
  ) {
    return this.auth.createStaff(actor, value);
  }
  @Patch(":id") update(
    @CurrentUser() actor: AuthenticatedUser,
    @Param("id") id: string,
    @Body() value: unknown,
  ) {
    return this.auth.update(actor, id, value);
  }
}

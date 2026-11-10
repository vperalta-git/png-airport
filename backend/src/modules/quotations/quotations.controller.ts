import { Controller, Get, Post, Param, Body } from "@nestjs/common";
import { QuotationRequest } from "@png-transfer/types";
import { QuotationsService } from "./quotations.service";
import { CanonicalQuotationPipe } from "../../contracts/canonical.pipe";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { AuthenticatedUser } from "../../common/guards/auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { Workflow } from "../../common/workflow";
@Controller("quotes")
@Workflow()
@Roles("PASSENGER")
export class QuotationsController {
  constructor(private readonly quotes: QuotationsService) {}
  @Post() create(
    @Body(new CanonicalQuotationPipe()) value: QuotationRequest,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.quotes.create(value.input, actor);
  }
  @Get(":id") get(
    @Param("id") id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.quotes.own(id, actor);
  }
}

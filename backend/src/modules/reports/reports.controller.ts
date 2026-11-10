import { Controller, Get } from "@nestjs/common";
import { ReportsService } from "./reports.service";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { AuthenticatedUser } from "../../common/guards/auth.guard";
import { Workflow } from "../../common/workflow";
@Controller("reports")
@Workflow()
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}
  @Get("dashboard") summary(@CurrentUser() a: AuthenticatedUser) {
    return this.reports.summary(a);
  }
  @Get("audit") audit(@CurrentUser() a: AuthenticatedUser) {
    return this.reports.audit(a);
  }
}

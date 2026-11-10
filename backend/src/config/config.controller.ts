import { Controller, Get } from "@nestjs/common";
import { PublicWorkflow } from "../common/workflow";
import { demoCatalog } from "./demo";
@Controller("config")
export class ConfigController {
  @Get() @PublicWorkflow() get() {
    return demoCatalog();
  }
}

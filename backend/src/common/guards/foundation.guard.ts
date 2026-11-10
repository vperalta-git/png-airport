import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { WORKFLOW } from "../workflow";
@Injectable()
export class FoundationGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}
  canActivate(context: ExecutionContext): boolean {
    const path = context.switchToHttp().getRequest().path.replace(/\/$/, "");
    if (
      ["/api/v1/health", "/api/v1/contracts"].includes(path) ||
      this.reflector.getAllAndOverride<boolean>(WORKFLOW, [
        context.getHandler(),
        context.getClass(),
      ])
    )
      return true;
    throw new ServiceUnavailableException({
      code: "WORKFLOW_NOT_READY",
      message: "This workflow is not configured for the isolated demo.",
    });
  }
}

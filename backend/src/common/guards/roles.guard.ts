import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { UserRole } from "@png-transfer/types";
import { ROLES_KEY } from "../decorators/roles.decorator";
import { PUBLIC } from "../workflow";
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest(),
      path = request.path?.replace(/\/$/, "");
    if (
      ["/api/v1/health", "/api/v1/contracts"].includes(path) ||
      this.reflector.getAllAndOverride<boolean>(PUBLIC, [
        context.getHandler(),
        context.getClass(),
      ])
    )
      return true;
    const required = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (
      !request.user ||
      (required?.length && !required.includes(request.user.role))
    )
      throw new ForbiddenException("Role does not permit this action.");
    return true;
  }
}

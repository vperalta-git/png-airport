import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { Actor, ROLES, UserRole, documentId } from "@png-transfer/types";
import { FirebaseService } from "../../firebase/firebase.service";
import { PUBLIC } from "../workflow";
export interface AuthenticatedUser extends Actor {
  email?: string;
  branchId?: string;
}
@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly reflector: Reflector = new Reflector(),
  ) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest(),
      path = request.path?.replace(/\/$/, "");
    if (
      ["/api/v1/health", "/api/v1/contracts"].includes(path) ||
      (context.getHandler &&
        this.reflector.getAllAndOverride<boolean>(PUBLIC, [
          context.getHandler(),
          context.getClass(),
        ]))
    )
      return true;
    const header = request.headers.authorization;
    if (typeof header !== "string" || !/^Bearer \S+$/.test(header))
      throw new UnauthorizedException("A Firebase ID token is required.");
    let actor: AuthenticatedUser;
    try {
      const token = await this.firebaseService.auth.verifyIdToken(
        header.slice(7),
        true,
      );
      if (!ROLES.includes(token.role as UserRole))
        throw new Error("Missing role");
      const ids = (value: unknown): string[] => {
        if (!Array.isArray(value) || !value.length)
          throw new Error("Missing scope");
        return value.map((v) => documentId(v));
      };
      actor = {
        uid: documentId(token.uid),
        email: token.email,
        role: token.role,
        organizationId: documentId(token.organizationId),
        branchIds: ids(token.branchIds),
        airportIds: ids(token.airportIds),
      };
    } catch {
      throw new UnauthorizedException(
        "Invalid, expired, revoked or incompletely scoped Firebase ID token.",
      );
    }
    let profile;
    try {
      profile = await this.firebaseService.firestore
        .collection("users")
        .doc(actor.uid)
        .get();
    } catch {
      throw new ServiceUnavailableException(
        "Account verification is temporarily unavailable",
      );
    }
    const data = profile.data();
    if (
      !data ||
      data.active !== true ||
      data.role !== actor.role ||
      data.organizationId !== actor.organizationId
    )
      throw new UnauthorizedException("Account is unavailable. Sign in again.");
    request.user = actor;
    return true;
  }
}

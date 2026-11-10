import {
  Injectable,
  BadRequestException,
  ConflictException,
  NotFoundException,
} from "@nestjs/common";
import { Actor, UserRole } from "@png-transfer/types";
import { FirebaseService } from "../../firebase/firebase.service";
import {
  body,
  text,
  email,
  phone,
  DEMO_SCOPE,
  staff,
  inScope,
  id,
  now,
  localScope,
} from "../../common/workflow";
export interface UserProfile {
  uid: string;
  fullName: string;
  email: string;
  phone?: string;
  role: UserRole;
  active: boolean;
  organizationId: string;
  branchId: string;
  airportId: string;
  createdAt: string;
}
@Injectable()
export class AuthService {
  constructor(private readonly firebase: FirebaseService) {}
  private async create(
    data: Record<string, unknown>,
    role: UserRole,
    scope = DEMO_SCOPE,
  ): Promise<UserProfile> {
    const fullName = text(data.fullName, "full name"),
      address = email(data.email),
      password = data.password;
    if (
      typeof password !== "string" ||
      password.length < 10 ||
      password.length > 128
    )
      throw new BadRequestException(
        "Use 10 to 128 characters for the password",
      );
    const contact = phone(data.phone);
    let uid: string | undefined;
    try {
      const user = await this.firebase.auth.createUser({
        email: address,
        password,
        displayName: fullName,
      });
      uid = user.uid;
      const profile: UserProfile = {
        uid,
        fullName,
        email: address,
        ...(contact ? { phone: contact } : {}),
        role,
        active: true,
        ...scope,
        createdAt: now(),
      };
      await this.firebase.auth.setCustomUserClaims(uid, {
        role,
        organizationId: scope.organizationId,
        branchIds: [scope.branchId],
        airportIds: [scope.airportId],
      });
      await this.firebase.firestore
        .collection("users")
        .doc(uid)
        .create(profile);
      return profile;
    } catch (error) {
      if (uid) await this.firebase.auth.deleteUser(uid).catch(() => {});
      if (error.code === "auth/email-already-exists")
        throw new ConflictException("Email is already registered");
      throw error;
    }
  }
  register(value: unknown) {
    const data = body(value, [
      "schemaVersion",
      "fullName",
      "email",
      "password",
      "phone",
    ]);
    if (data.schemaVersion !== "1")
      throw new BadRequestException("Unsupported schemaVersion");
    return this.create(data, "PASSENGER");
  }
  async me(actor: Actor): Promise<UserProfile> {
    const doc = await this.firebase.firestore
      .collection("users")
      .doc(actor.uid)
      .get();
    if (!doc.exists) throw new NotFoundException("Account not found");
    return doc.data() as UserProfile;
  }
  async list(actor: Actor) {
    staff(actor, true);
    const snapshot = await this.firebase.firestore
      .collection("users")
      .where("organizationId", "==", actor.organizationId)
      .get();
    return snapshot.docs
      .map((d) => d.data() as UserProfile)
      .filter((u) => inScope(actor, u));
  }
  async createStaff(actor: Actor, value: unknown) {
    staff(actor, true);
    const data = body(value, [
      "fullName",
      "email",
      "password",
      "phone",
      "role",
    ]);
    if (!["DISPATCHER", "DRIVER", "SUPERVISOR"].includes(data.role as string))
      throw new BadRequestException("Choose a supported staff role");
    const scope = localScope(actor),
      profile = await this.create(data, data.role as UserRole, scope);
    await this.firebase.firestore
      .collection("audit_logs")
      .add({
        ...scope,
        actorId: actor.uid,
        action: "STAFF_CREATED",
        resourceId: profile.uid,
        timestamp: now(),
      });
    return profile;
  }
  async update(actor: Actor, userId: string, value: unknown) {
    staff(actor, true);
    id(userId);
    const data = body(value, ["fullName", "phone", "active"]),
      ref = this.firebase.firestore.collection("users").doc(userId);
    const current = (await ref.get()).data() as UserProfile;
    if (!current || !inScope(actor, current))
      throw new NotFoundException("Account not found");
    const changes: Partial<UserProfile> = {};
    if (data.fullName !== undefined)
      changes.fullName = text(data.fullName, "full name");
    if (data.phone !== undefined) changes.phone = phone(data.phone) ?? "";
    if (data.active !== undefined) {
      if (typeof data.active !== "boolean")
        throw new BadRequestException("active must be boolean");
      if (actor.uid === userId && !data.active)
        throw new BadRequestException("You cannot suspend your own account");
      changes.active = data.active;
      if (!data.active) {
        await ref.update({ active: false });
        await this.firebase.auth.updateUser(userId, { disabled: true });
        await this.firebase.auth.revokeRefreshTokens(userId);
      } else await this.firebase.auth.updateUser(userId, { disabled: false });
    }
    await ref.update(changes);
    await this.firebase.firestore
      .collection("audit_logs")
      .add({
        actorId: actor.uid,
        organizationId: actor.organizationId,
        branchId: current.branchId,
        airportId: current.airportId,
        action: "ACCOUNT_UPDATED",
        resourceId: userId,
        timestamp: now(),
      });
    return (await ref.get()).data();
  }
  async logout(actor: Actor) {
    await this.firebase.auth.revokeRefreshTokens(actor.uid);
    return { revoked: true };
  }
}

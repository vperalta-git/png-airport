import {
  applyDecorators,
  SetMetadata,
  BadRequestException,
  ForbiddenException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { Actor, documentId, Scope } from "@png-transfer/types";
export const WORKFLOW = "aerotrans.workflow",
  PUBLIC = "aerotrans.public";
export const Workflow = () => SetMetadata(WORKFLOW, true);
export const PublicWorkflow = () =>
  applyDecorators(Workflow(), SetMetadata(PUBLIC, true));
export const DEMO_SCOPE = {
  organizationId: "demo-aerotrans",
  branchId: "demo-lae",
  airportId: "airport_nadzab_lae",
};
export const now = () => new Date().toISOString();
export function body(
  value: unknown,
  allowed: string[],
): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new BadRequestException("JSON object required");
  const data = value as Record<string, unknown>;
  if (Object.keys(data).some((k) => !allowed.includes(k)))
    throw new BadRequestException("Unexpected request field");
  return data;
}
export function text(value: unknown, name: string, max = 160): string {
  if (typeof value !== "string" || !value.trim() || value.trim().length > max)
    throw new BadRequestException("Invalid " + name);
  return value.trim();
}
export function id(value: unknown, name = "id"): string {
  try {
    return documentId(value, name);
  } catch {
    throw new BadRequestException("Invalid " + name);
  }
}
export function email(value: unknown): string {
  const result = text(value, "email", 254).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(result))
    throw new BadRequestException("Enter a valid email address");
  return result;
}
export function phone(value: unknown): string | undefined {
  if (value === undefined || value === "") return undefined;
  let result = text(value, "phone", 32).replace(/[\s()-]/g, "");
  if (/^[0-9]{8}$/.test(result)) result = "+675" + result;
  if (!/^\+[1-9][0-9]{7,14}$/.test(result))
    throw new BadRequestException("Use a valid +country-code phone number");
  return result;
}
export function inScope(actor: Actor, value: unknown): boolean {
  if (!value || typeof value !== "object") return false;
  const record = value as Partial<Scope>;
  return (
    record.organizationId === actor.organizationId &&
    actor.branchIds.includes(record.branchId) &&
    actor.airportIds.includes(record.airportId)
  );
}
export function localScope(actor: Actor) {
  if (
    !actor.branchIds.includes(DEMO_SCOPE.branchId) ||
    !actor.airportIds.includes(DEMO_SCOPE.airportId)
  )
    throw new ForbiddenException("Configured Lae scope required");
  return { ...DEMO_SCOPE, organizationId: actor.organizationId };
}
export function staff(actor: Actor, manager = false) {
  if (
    !(
      manager
        ? ["SUPERVISOR", "SUPER_ADMIN"]
        : ["DISPATCHER", "SUPERVISOR", "SUPER_ADMIN"]
    ).includes(actor.role)
  )
    throw new ForbiddenException("Staff permission required");
}
export function unavailable(message: string): never {
  throw new ServiceUnavailableException({
    code: "WORKFLOW_NOT_READY",
    message,
  });
}

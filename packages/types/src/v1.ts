/** Authoritative API v1 boundary. All document IDs are opaque strings. */
export const CONTRACT_VERSION = "1" as const;
export const ROLES = [
  "PASSENGER",
  "DISPATCHER",
  "DRIVER",
  "SUPERVISOR",
  "SUPER_ADMIN",
  "SECURITY",
  "OPERATOR",
  "CORPORATE_BOOKER",
] as const;
export type UserRole = (typeof ROLES)[number];
export const BOOKING_STATUSES = [
  "DRAFT",
  "QUOTATION",
  "BOOKING_REQUESTED",
  "AVAILABILITY_CONFIRMED",
  "CONFIRMED",
  "DISPATCHED",
  "DRIVER_EN_ROUTE",
  "AT_AIRPORT",
  "PASSENGER_VERIFIED",
  "TRANSFER_IN_PROGRESS",
  "ARRIVED_DESTINATION",
  "COMPLETED",
  "CLOSED",
  "CANCELLED",
] as const;
export type BookingStatus = (typeof BOOKING_STATUSES)[number];
export const PAYMENT_STATUSES = [
  "PENDING",
  "AUTHORIZED",
  "PAID",
  "FAILED",
  "REFUNDED",
  "CANCELLED",
] as const;
export type PaymentStatus = (typeof PAYMENT_STATUSES)[number];
export const VEHICLE_CATEGORIES = [
  "STANDARD_SEDAN",
  "EXECUTIVE_SUV",
  "HEAVY_4WD",
  "ARMORED_SUV",
  "COASTER_BUS",
] as const;
export const ESCORT_TYPES = [
  "NONE",
  "STATIC_OFFICER",
  "ARMED_ESCORT_CHASE_VEHICLE",
  "CLOSE_PROTECTION_CONVOY",
] as const;
export const DIRECTIONS = [
  "INBOUND_AIRPORT_TO_CITY",
  "OUTBOUND_CITY_TO_AIRPORT",
  "INTERCITY_TRANSFER",
] as const;
export interface Scope {
  organizationId: string;
  branchId: string;
  airportId: string;
  customerId: string;
}
export interface Actor {
  uid: string;
  role: UserRole;
  organizationId: string;
  branchIds: string[];
  airportIds: string[];
}
export interface Pricing {
  currency: "PGK";
  subtotalMinor: number;
  taxMinor: number;
  totalMinor: number;
}
export interface TransferInput {
  airportId: string;
  direction: (typeof DIRECTIONS)[number];
  vehicleCategory: (typeof VEHICLE_CATEGORIES)[number];
  securityEscortType: (typeof ESCORT_TYPES)[number];
  pickupDateTime: string;
  destinationAddress: string;
  passengerCount: number;
  luggageCount: number;
}
export interface Quotation extends Scope {
  schemaVersion: typeof CONTRACT_VERSION;
  id: string;
  input: TransferInput;
  pricing: Pricing;
  rateVersion: string;
  createdAt: string;
  expiresAt: string;
}
export interface Booking extends Scope {
  schemaVersion: typeof CONTRACT_VERSION;
  id: string;
  referenceNumber: string;
  quotationId: string;
  rateVersion: string;
  input: TransferInput;
  pricing: Pricing;
  status: BookingStatus;
  payment: {
    status: PaymentStatus;
    method?:
      | "CASH_ON_BOARD"
      | "BANK_TRANSFER_BSP"
      | "CARD_GATEWAY"
      | "CORPORATE_CREDIT";
    providerReference?: string;
    verifiedAt?: string;
  };
  passengers: { fullName: string; phone?: string; email?: string }[];
  dispatch?: {
    assignedDriverId: string;
    assignedVehicleId: string;
    assignedSecurityGuardId?: string;
    acceptedAt?: string;
  };
  revision: number;
  createdAt: string;
  updatedAt: string;
}
export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}
export type ApiResponse<T> =
  | {
      schemaVersion: "1";
      success: true;
      data: T;
      error: null;
      meta: ResponseMeta;
    }
  | {
      schemaVersion: "1";
      success: false;
      data: null;
      error: ApiError;
      meta: ResponseMeta;
    };
export interface ResponseMeta {
  timestamp: string;
  timezone: "Pacific/Port_Moresby";
  requestId: string;
}

type Obj = Record<string, unknown>;
function object(value: unknown, name: string): Obj {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new Error(name + " must be an object");
  return value as Obj;
}
export function documentId(value: unknown, name = "id"): string {
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value !== value.trim() ||
    value.includes("/") ||
    value === "." ||
    value === ".."
  )
    throw new Error(name + " must be a nonempty document ID string");
  return value;
}
function text(value: unknown, name: string): string {
  if (typeof value !== "string" || !value.trim())
    throw new Error(name + " is required");
  return value;
}
function member<T extends string>(
  value: unknown,
  values: readonly T[],
  name: string,
): T {
  if (typeof value !== "string" || !values.includes(value as T))
    throw new Error("Invalid " + name);
  return value as T;
}
function integer(value: unknown, name: string, min = 0): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < min)
    throw new Error(name + " must be a safe integer >= " + min);
  return value;
}
export function timestamp(value: unknown, name = "timestamp"): string {
  const result = text(value, name);
  if (
    !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,3})?(?:Z|[+-]\d\d:\d\d)$/.test(
      result,
    ) ||
    !Number.isFinite(Date.parse(result))
  )
    throw new Error(name + " must be an ISO timestamp with offset");
  const parts =
    /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d{1,3})?(Z|[+-](\d\d):(\d\d))$/.exec(
      result,
    )!;
  const [, y, m, d, h, minute, s, , oh, om] = parts;
  if (
    +m < 1 ||
    +m > 12 ||
    +d < 1 ||
    +d > new Date(Date.UTC(+y, +m, 0)).getUTCDate() ||
    +h > 23 ||
    +minute > 59 ||
    +s > 59 ||
    (oh !== undefined && (+oh > 23 || +om > 59))
  )
    throw new Error(name + " has an invalid calendar/time value");
  return result;
}
function scope(o: Obj): Scope {
  return {
    organizationId: documentId(o.organizationId, "organizationId"),
    branchId: documentId(o.branchId, "branchId"),
    airportId: documentId(o.airportId, "airportId"),
    customerId: documentId(o.customerId, "customerId"),
  };
}
function version(o: Obj) {
  if (o.schemaVersion !== CONTRACT_VERSION)
    throw new Error("Unsupported schemaVersion");
}
export function parsePricing(value: unknown): Pricing {
  const o = object(value, "pricing");
  if (o.currency !== "PGK") throw new Error("Currency must be PGK");
  const subtotalMinor = integer(o.subtotalMinor, "subtotalMinor"),
    taxMinor = integer(o.taxMinor, "taxMinor"),
    totalMinor = integer(o.totalMinor, "totalMinor");
  if (
    !Number.isSafeInteger(subtotalMinor + taxMinor) ||
    subtotalMinor + taxMinor !== totalMinor
  )
    throw new Error("Pricing total does not balance");
  return { currency: "PGK", subtotalMinor, taxMinor, totalMinor };
}
export function parseTransferInput(value: unknown): TransferInput {
  const o = object(value, "input");
  return {
    airportId: documentId(o.airportId, "airportId"),
    direction: member(o.direction, DIRECTIONS, "direction"),
    vehicleCategory: member(
      o.vehicleCategory,
      VEHICLE_CATEGORIES,
      "vehicleCategory",
    ),
    securityEscortType: member(
      o.securityEscortType,
      ESCORT_TYPES,
      "securityEscortType",
    ),
    pickupDateTime: timestamp(o.pickupDateTime, "pickupDateTime"),
    destinationAddress: text(o.destinationAddress, "destinationAddress"),
    passengerCount: integer(o.passengerCount, "passengerCount", 1),
    luggageCount: integer(o.luggageCount, "luggageCount"),
  };
}
export function parseQuotation(value: unknown): Quotation {
  const o = object(value, "quotation");
  version(o);
  const input = parseTransferInput(o.input),
    s = scope(o);
  if (input.airportId !== s.airportId)
    throw new Error("Quote airport scope mismatch");
  const createdAt = timestamp(o.createdAt, "createdAt"),
    expiresAt = timestamp(o.expiresAt, "expiresAt");
  if (Date.parse(expiresAt) <= Date.parse(createdAt))
    throw new Error("Quote expiry must follow creation");
  return {
    schemaVersion: CONTRACT_VERSION,
    ...s,
    id: documentId(o.id),
    input,
    pricing: parsePricing(o.pricing),
    rateVersion: text(o.rateVersion, "rateVersion"),
    createdAt,
    expiresAt,
  };
}
export function parseBooking(value: unknown): Booking {
  const o = object(value, "booking");
  version(o);
  const input = parseTransferInput(o.input),
    s = scope(o);
  if (input.airportId !== s.airportId)
    throw new Error("Booking airport scope mismatch");
  const payment = object(o.payment, "payment");
  const p: Booking["payment"] = {
    status: member(payment.status, PAYMENT_STATUSES, "payment status"),
  };
  if (payment.method !== undefined)
    p.method = member(
      payment.method,
      [
        "CASH_ON_BOARD",
        "BANK_TRANSFER_BSP",
        "CARD_GATEWAY",
        "CORPORATE_CREDIT",
      ] as const,
      "payment method",
    );
  if (payment.providerReference !== undefined)
    p.providerReference = text(payment.providerReference, "providerReference");
  if (payment.verifiedAt !== undefined)
    p.verifiedAt = timestamp(payment.verifiedAt, "verifiedAt");
  if (p.status === "PAID" && (!p.providerReference || !p.verifiedAt))
    throw new Error("PAID requires verified evidence");
  if (
    !Array.isArray(o.passengers) ||
    o.passengers.length !== input.passengerCount
  )
    throw new Error("Manifest must match passengerCount");
  const passengers = o.passengers.map((v) => {
    const item = object(v, "passenger");
    return {
      fullName: text(item.fullName, "fullName"),
      ...(item.phone !== undefined ? { phone: text(item.phone, "phone") } : {}),
      ...(item.email !== undefined ? { email: text(item.email, "email") } : {}),
    };
  });
  let dispatch: Booking["dispatch"];
  if (o.dispatch !== undefined) {
    const d = object(o.dispatch, "dispatch");
    dispatch = {
      assignedDriverId: documentId(d.assignedDriverId, "assignedDriverId"),
      assignedVehicleId: documentId(d.assignedVehicleId, "assignedVehicleId"),
      ...(d.assignedSecurityGuardId !== undefined
        ? {
            assignedSecurityGuardId: documentId(
              d.assignedSecurityGuardId,
              "assignedSecurityGuardId",
            ),
          }
        : {}),
      ...(d.acceptedAt !== undefined
        ? { acceptedAt: timestamp(d.acceptedAt, "acceptedAt") }
        : {}),
    };
  }
  const createdAt = timestamp(o.createdAt, "createdAt"),
    updatedAt = timestamp(o.updatedAt, "updatedAt");
  if (Date.parse(updatedAt) < Date.parse(createdAt))
    throw new Error("updatedAt precedes createdAt");
  return {
    schemaVersion: CONTRACT_VERSION,
    ...s,
    id: documentId(o.id),
    referenceNumber: text(o.referenceNumber, "referenceNumber"),
    quotationId: documentId(o.quotationId, "quotationId"),
    rateVersion: text(o.rateVersion, "rateVersion"),
    input,
    pricing: parsePricing(o.pricing),
    status: member(o.status, BOOKING_STATUSES, "booking status"),
    payment: p,
    passengers,
    ...(dispatch ? { dispatch } : {}),
    revision: integer(o.revision, "revision"),
    createdAt,
    updatedAt,
  };
}
export type Permission =
  | "BOOK_OWN"
  | "DISPATCH"
  | "EXECUTE_ASSIGNED"
  | "MANAGE_STAFF"
  | "MANAGE_RESOURCES"
  | "REVIEW_AUDIT";
export const ROLE_PERMISSIONS: Record<UserRole, readonly Permission[]> = {
  PASSENGER: ["BOOK_OWN"],
  DISPATCHER: ["DISPATCH"],
  DRIVER: ["EXECUTE_ASSIGNED"],
  SUPERVISOR: ["DISPATCH", "MANAGE_STAFF", "MANAGE_RESOURCES", "REVIEW_AUDIT"],
  SUPER_ADMIN: ["DISPATCH", "MANAGE_STAFF", "MANAGE_RESOURCES", "REVIEW_AUDIT"],
  SECURITY: [],
  OPERATOR: [],
  CORPORATE_BOOKER: [],
};
export function canReadBooking(actor: Actor, booking: Booking): boolean {
  if (
    actor.organizationId !== booking.organizationId ||
    !actor.branchIds.includes(booking.branchId) ||
    !actor.airportIds.includes(booking.airportId)
  )
    return false;
  if (actor.role === "PASSENGER") return actor.uid === booking.customerId;
  if (actor.role === "DRIVER")
    return actor.uid === booking.dispatch?.assignedDriverId;
  return ["DISPATCHER", "SUPERVISOR", "SUPER_ADMIN"].includes(actor.role);
}
/** Policy definition. The API service must also atomically check revision, assignment and OTP. */
export function canTransition(
  role: UserRole,
  from: BookingStatus,
  to: BookingStatus,
): boolean {
  if (
    role === "PASSENGER" &&
    ((from === "DRAFT" && to === "QUOTATION") ||
      (from === "QUOTATION" && to === "BOOKING_REQUESTED"))
  )
    return true;
  if (to === "CANCELLED")
    return (
      ["PASSENGER", "DISPATCHER", "SUPERVISOR"].includes(role) &&
      [
        "BOOKING_REQUESTED",
        "AVAILABILITY_CONFIRMED",
        "CONFIRMED",
        "DISPATCHED",
      ].includes(from)
    );
  if (role === "SUPERVISOR" && from === "COMPLETED" && to === "CLOSED")
    return true;
  if (
    ["DISPATCHER", "SUPERVISOR"].includes(role) &&
    ((from === "BOOKING_REQUESTED" && to === "AVAILABILITY_CONFIRMED") ||
      (from === "AVAILABILITY_CONFIRMED" && to === "CONFIRMED") ||
      (from === "CONFIRMED" && to === "DISPATCHED"))
  )
    return true;
  // AT_AIRPORT -> PASSENGER_VERIFIED is deliberately not a generic state change.
  return (
    role === "DRIVER" &&
    [
      "DISPATCHED:DRIVER_EN_ROUTE",
      "DRIVER_EN_ROUTE:AT_AIRPORT",
      "PASSENGER_VERIFIED:TRANSFER_IN_PROGRESS",
      "TRANSFER_IN_PROGRESS:ARRIVED_DESTINATION",
      "ARRIVED_DESTINATION:COMPLETED",
    ].includes(from + ":" + to)
  );
}

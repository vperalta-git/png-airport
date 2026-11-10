import {
  CONTRACT_VERSION,
  TransferInput,
  documentId,
  parseTransferInput,
} from "./v1";
export interface QuotationRequest {
  schemaVersion: "1";
  input: TransferInput;
}
export interface BookingRequest {
  schemaVersion: "1";
  quotationId: string;
  idempotencyKey: string;
  paymentMethod:
    | "CASH_ON_BOARD"
    | "BANK_TRANSFER_BSP"
    | "CARD_GATEWAY"
    | "CORPORATE_CREDIT";
  passengers: { fullName: string; phone?: string; email?: string }[];
  customerId?: string;
}
function exact(value: unknown, keys: string[]): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new Error("Request must be an object");
  const body = value as Record<string, unknown>;
  if (body.schemaVersion !== CONTRACT_VERSION)
    throw new Error("Unsupported schemaVersion");
  if (Object.keys(body).some((k) => !keys.includes(k)))
    throw new Error("Unexpected request field");
  return body;
}
export function parseQuotationRequest(value: unknown): QuotationRequest {
  const body = exact(value, ["schemaVersion", "input"]);
  return {
    schemaVersion: CONTRACT_VERSION,
    input: parseTransferInput(body.input),
  };
}
export function parseBookingRequest(value: unknown): BookingRequest {
  const body = exact(value, [
    "schemaVersion",
    "quotationId",
    "idempotencyKey",
    "paymentMethod",
    "passengers",
    "customerId",
  ]);
  const methods = [
    "CASH_ON_BOARD",
    "BANK_TRANSFER_BSP",
    "CARD_GATEWAY",
    "CORPORATE_CREDIT",
  ];
  if (
    typeof body.paymentMethod !== "string" ||
    !methods.includes(body.paymentMethod)
  )
    throw new Error("Invalid payment method");
  if (!Array.isArray(body.passengers) || !body.passengers.length)
    throw new Error("Passenger manifest is required");
  const passengers = body.passengers.map((p) => {
    if (!p || typeof p !== "object" || Array.isArray(p))
      throw new Error("Invalid passenger");
    const record = p as Record<string, unknown>;
    if (
      Object.keys(record).some(
        (k) => !["fullName", "phone", "email"].includes(k),
      )
    )
      throw new Error("Unexpected passenger field");
    for (const key of [
      "fullName",
      ...["phone", "email"].filter((k) => record[k] !== undefined),
    ]) {
      if (typeof record[key] !== "string" || !(record[key] as string).trim())
        throw new Error("Invalid passenger " + key);
    }
    return record as BookingRequest["passengers"][number];
  });
  return {
    schemaVersion: CONTRACT_VERSION,
    quotationId: documentId(body.quotationId, "quotationId"),
    idempotencyKey: documentId(body.idempotencyKey, "idempotencyKey"),
    paymentMethod: body.paymentMethod as BookingRequest["paymentMethod"],
    passengers,
    ...(body.customerId !== undefined
      ? { customerId: documentId(body.customerId, "customerId") }
      : {}),
  };
}

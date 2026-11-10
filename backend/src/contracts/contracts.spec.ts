import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  parseBooking,
  parseQuotation,
  canTransition,
  ROLE_PERMISSIONS,
} from "@png-transfer/types";
import { CanonicalBookingPipe, CanonicalQuotationPipe } from "./canonical.pipe";
const fixture = (name: string) =>
  JSON.parse(
    readFileSync(
      resolve(__dirname, "../../../packages/types/fixtures", name + ".v1.json"),
      "utf8",
    ),
  );
describe("shared v1 wire contract at the Nest boundary", () => {
  it("Nest request pipes validate the canonical shape and reject client money/identity overrides", () => {
    const quote = fixture("quotation"),
      booking = fixture("booking");
    expect(
      new CanonicalQuotationPipe().transform({
        schemaVersion: "1",
        input: quote.input,
      }).input.airportId,
    ).toBe(quote.airportId);
    const request = {
      schemaVersion: "1",
      quotationId: quote.id,
      idempotencyKey: "test-only-key",
      paymentMethod: "CASH_ON_BOARD",
      passengers: booking.passengers,
    };
    expect(new CanonicalBookingPipe().transform(request).quotationId).toBe(
      quote.id,
    );
    for (const extra of [
      { totalFare: 1 },
      { paymentStatus: "PAID" },
      { organizationId: "other" },
      { assignedDriverId: "fake" },
    ]) {
      expect(() =>
        new CanonicalBookingPipe().transform({ ...request, ...extra }),
      ).toThrow();
    }
  });
  it("parses opaque Firebase IDs and PGK integer minor units without defaults", () => {
    expect(parseBooking(fixture("booking")).id).toBe("BK-test-only");
    expect(parseQuotation(fixture("quotation")).pricing.totalMinor).toBe(12345);
    expect(() => parseBooking({ ...fixture("booking"), id: 123 })).toThrow();
  });
  it("defines operational supervision separately from system administration", () => {
    expect(ROLE_PERMISSIONS.SUPERVISOR).toContain("REVIEW_AUDIT");
    expect(ROLE_PERMISSIONS.PASSENGER).not.toContain("MANAGE_STAFF");
    expect(canTransition("DRIVER", "AT_AIRPORT", "PASSENGER_VERIFIED")).toBe(
      false,
    );
  });
});

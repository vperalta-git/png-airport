import { QuotationsService } from "./quotations.service";
import { Actor, TransferInput } from "@png-transfer/types";
const actor: Actor = {
  uid: "customer",
  role: "PASSENGER",
  organizationId: "test-org",
  branchIds: ["demo-lae"],
  airportIds: ["airport_nadzab_lae"],
};
const input = (): TransferInput => ({
  airportId: "airport_nadzab_lae",
  direction: "INBOUND_AIRPORT_TO_CITY",
  vehicleCategory: "STANDARD_SEDAN",
  securityEscortType: "NONE",
  pickupDateTime: new Date(Date.now() + 3600000).toISOString(),
  destinationAddress: "TEST ONLY destination",
  passengerCount: 1,
  luggageCount: 1,
});
describe("authoritative isolated quotes", () => {
  const prior = process.env.AEROTRANS_DEMO_RATES;
  afterEach(() => {
    if (prior === undefined) delete process.env.AEROTRANS_DEMO_RATES;
    else process.env.AEROTRANS_DEMO_RATES = prior;
  });
  it("does not create a quote when rates are not explicitly enabled", async () => {
    delete process.env.AEROTRANS_DEMO_RATES;
    const create = jest.fn(),
      service = new QuotationsService({
        firestore: { collection: () => ({ doc: () => ({ create }) }) },
      } as any);
    await expect(service.create(input(), actor)).rejects.toThrow(
      "Approved fares",
    );
    expect(create).not.toHaveBeenCalled();
  });
  it("uses a labelled server minor-unit quote and propagates persistence failures", async () => {
    process.env.AEROTRANS_DEMO_RATES = "true";
    const create = jest.fn().mockResolvedValue(undefined),
      service = new QuotationsService({
        firestore: { collection: () => ({ doc: () => ({ create }) }) },
      } as any);
    const quote = await service.create(input(), actor);
    expect(quote.customerId).toBe(actor.uid);
    expect(quote.pricing.totalMinor).toBe(10000);
    expect(quote.rateVersion).toContain("DEMO-ONLY");
    create.mockRejectedValue(new Error("Database offline"));
    await expect(service.create(input(), actor)).rejects.toThrow(
      "Database offline",
    );
  });
});

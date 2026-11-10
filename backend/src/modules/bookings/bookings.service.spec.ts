import { BookingsService } from "./bookings.service";
describe("booking read scope", () => {
  it("never provides an unscoped internal read adapter", async () => {
    const service = new BookingsService({} as any);
    await expect(service.getBooking("BK-test")).rejects.toThrow(
      "Scoped actor required",
    );
  });
});

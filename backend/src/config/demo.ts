import { ServiceUnavailableException } from "@nestjs/common";
export const DEMO_RATE_VERSION = "DEMO-ONLY-NOT-OPERATOR-APPROVED-1";
export const DEMO_CATEGORIES = [
  {
    id: "STANDARD_SEDAN",
    name: "Sedan",
    passengerCapacity: 3,
    luggageCapacity: 2,
    testFareMinor: 10000,
  },
  {
    id: "EXECUTIVE_SUV",
    name: "SUV",
    passengerCapacity: 5,
    luggageCapacity: 4,
    testFareMinor: 15000,
  },
];
export function demoCatalog() {
  return {
    country: "PG",
    currency: "PGK",
    timezone: "Pacific/Port_Moresby",
    demoMode: true,
    airports: [
      {
        id: "airport_nadzab_lae",
        iata: "LAE",
        name: "Nadzab Tomodachi International Airport",
        timezone: "Pacific/Port_Moresby",
      },
    ],
    destinations: [{ id: "lae-demo", name: "Lae - demo destination" }],
    vehicleCategories: DEMO_CATEGORIES.map(
      ({ testFareMinor, ...category }) => category,
    ),
    pricingConfigured: process.env.AEROTRANS_DEMO_RATES === "true",
    pricingNotice:
      "ISOLATED DEMO: test fares only. No operator-approved commercial rates or live payments.",
  };
}
export function demoFare(category: string) {
  if (process.env.AEROTRANS_DEMO_RATES !== "true")
    throw new ServiceUnavailableException({
      code: "PRICING_NOT_CONFIGURED",
      message:
        "Approved fares are unavailable. Start the isolated demo explicitly to use labelled test fares.",
    });
  const found = DEMO_CATEGORIES.find((c) => c.id === category);
  if (!found)
    throw new ServiceUnavailableException(
      "This vehicle category is not configured for the demo",
    );
  return {
    currency: "PGK" as const,
    subtotalMinor: found.testFareMinor,
    taxMinor: 0,
    totalMinor: found.testFareMinor,
  };
}

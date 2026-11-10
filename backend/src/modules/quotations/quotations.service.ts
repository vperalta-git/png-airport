import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import {
  Actor,
  Quotation,
  TransferInput,
  parseQuotation,
} from "@png-transfer/types";
import { FirebaseService } from "../../firebase/firebase.service";
import { DEMO_SCOPE, inScope, now, localScope } from "../../common/workflow";
import {
  demoFare,
  DEMO_RATE_VERSION,
  DEMO_CATEGORIES,
} from "../../config/demo";
export type QuotationEntity = Quotation;
@Injectable()
export class QuotationsService {
  constructor(private readonly firebase: FirebaseService) {}
  async create(input: TransferInput, actor: Actor): Promise<Quotation> {
    if (actor.role !== "PASSENGER")
      throw new BadRequestException(
        "Customer scope is required for a personal quote",
      );
    const pickup = Date.parse(input.pickupDateTime),
      clock = Date.now();
    if (
      input.airportId !== DEMO_SCOPE.airportId ||
      !["INBOUND_AIRPORT_TO_CITY", "OUTBOUND_CITY_TO_AIRPORT"].includes(
        input.direction,
      ) ||
      input.securityEscortType !== "NONE"
    )
      throw new BadRequestException(
        "Choose the supported Lae transfer service",
      );
    if (pickup < clock - 60000 || pickup > clock + 365 * 86400000)
      throw new BadRequestException("Choose a future pickup within one year");
    const category = DEMO_CATEGORIES.find(
      (c) => c.id === input.vehicleCategory,
    );
    if (
      !category ||
      input.passengerCount > category.passengerCapacity ||
      input.luggageCount > category.luggageCapacity
    )
      throw new BadRequestException(
        "Passenger or luggage count exceeds capacity",
      );
    const quote = parseQuotation({
      schemaVersion: "1",
      id: "QUO-" + randomUUID(),
      ...localScope(actor),
      customerId: actor.uid,
      input,
      pricing: demoFare(input.vehicleCategory),
      rateVersion: DEMO_RATE_VERSION,
      createdAt: now(),
      expiresAt: new Date(clock + 15 * 60000).toISOString(),
    });
    await this.firebase.firestore
      .collection("quotations")
      .doc(quote.id)
      .create(quote);
    return quote;
  }
  async findById(id: string): Promise<Quotation | null> {
    const doc = await this.firebase.firestore
      .collection("quotations")
      .doc(id)
      .get();
    return doc.exists ? parseQuotation(doc.data()) : null;
  }
  async own(id: string, actor: Actor) {
    const quote = await this.findById(id);
    if (!quote || quote.customerId !== actor.uid || !inScope(actor, quote))
      throw new NotFoundException("Quote not found");
    return quote;
  }
}

import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from "@nestjs/common";
import { v4 as uuidv4 } from "uuid";
import * as crypto from "crypto";
import { FirebaseService } from "../../firebase/firebase.service";
import { BookingsService } from "../bookings/bookings.service";

export interface TaxInvoiceEntity {
  id: string;
  invoiceNumber: string; // INV-YYYYMMDD-XXXX
  bookingId: string;
  bookingReference: string;
  organizationId: string;
  issuedTo: {
    name: string;
    email?: string;
    corporateAccount?: string;
    tin?: string; // Taxpayer Identification Number
  };
  lines: Array<{
    description: string;
    unitPrice: number;
    quantity: number;
    amount: number;
  }>;
  subtotal: number;
  gstAmount: number; // 10% PNG GST
  totalAmount: number;
  currency: "PGK";
  status: "ISSUED" | "PAID" | "VOIDED";
  issuedAt: string;
  dueAt: string;
  paidAt?: string;
}

export interface JournalEntry {
  id: string;
  transactionId: string;
  account:
    | "CASH_BANK"
    | "ACCOUNTS_RECEIVABLE"
    | "TRANSPORT_REVENUE"
    | "GST_PAYABLE"
    | "PARTNER_CLEARING";
  debit: number;
  credit: number;
  description: string;
  timestamp: string;
}

export interface PartnerSettlementEntity {
  id: string;
  settlementNumber: string; // SETTLE-YYYYMMDD-XXXX
  partnerOperatorId: string;
  bookingId: string;
  grossAmount: number;
  platformCommissionPercent: number; // e.g. 20%
  platformCommissionAmount: number;
  netPayoutToPartner: number;
  currency: "PGK";
  status: "PENDING_APPROVAL" | "APPROVED" | "DISBURSED";
  createdAt: string;
  settledAt?: string;
}

import { unavailable } from "../../common/workflow";
@Injectable()
export class PaymentsService {
  async generateTaxInvoice(_bookingId: string): Promise<TaxInvoiceEntity> {
    return unavailable(
      "Commercial invoicing and tax treatment are not configured.",
    );
  }
  async calculatePartnerSettlement(
    _bookingId: string,
    _operatorId: string,
  ): Promise<PartnerSettlementEntity> {
    return unavailable("Partner settlements are not configured.");
  }
  verifyWebhookSignature(
    _raw: string,
    _signature: string,
    _secret: string,
  ): boolean {
    return false;
  }
}

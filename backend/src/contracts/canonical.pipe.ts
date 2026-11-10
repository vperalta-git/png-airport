import { BadRequestException, Injectable, PipeTransform } from "@nestjs/common";
import {
  parseQuotationRequest,
  QuotationRequest,
  parseBookingRequest,
  BookingRequest,
} from "@png-transfer/types";
@Injectable()
export class CanonicalQuotationPipe
  implements PipeTransform<unknown, QuotationRequest>
{
  transform(value: unknown): QuotationRequest {
    try {
      return parseQuotationRequest(value);
    } catch (error) {
      throw new BadRequestException({
        code: "VALIDATION_ERROR",
        message:
          error instanceof Error ? error.message : "Invalid quotation request",
      });
    }
  }
}
@Injectable()
export class CanonicalBookingPipe
  implements PipeTransform<unknown, BookingRequest>
{
  transform(value: unknown): BookingRequest {
    try {
      return parseBookingRequest(value);
    } catch (error) {
      throw new BadRequestException({
        code: "VALIDATION_ERROR",
        message:
          error instanceof Error ? error.message : "Invalid booking request",
      });
    }
  }
}

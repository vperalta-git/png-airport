import { Controller, Post, Param, Body, Headers, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PaymentsService, TaxInvoiceEntity, PartnerSettlementEntity } from './payments.service';

@ApiTags('Payments & Invoicing')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('invoices/:bookingId')
  @ApiOperation({ summary: 'Generate PNG IRC-compliant Tax Invoice with 10% GST breakdown and ledger journal' })
  async generateInvoice(@Param('bookingId') bookingId: string): Promise<TaxInvoiceEntity> {
    return this.paymentsService.generateTaxInvoice(bookingId);
  }

  @Post('settlements/:bookingId')
  @ApiOperation({ summary: 'Calculate and generate 80/20 partner fleet operator revenue settlement' })
  async generateSettlement(
    @Param('bookingId') bookingId: string,
    @Body('partnerOperatorId') partnerOperatorId: string,
  ): Promise<PartnerSettlementEntity> {
    return this.paymentsService.calculatePartnerSettlement(bookingId, partnerOperatorId);
  }

  @Post('webhooks/bsp-gateway')
  @ApiOperation({ summary: 'Secure HMAC-SHA256 signature-verified webhook handler for PNG payment gateways' })
  async handlePaymentWebhook(
    @Body() payload: any,
    @Headers('x-signature') signature: string,
  ) {
    const secret = process.env.PAYMENT_GATEWAY_WEBHOOK_SECRET || 'dev_secret_png_2026';
    const raw = JSON.stringify(payload);
    const valid = this.paymentsService.verifyWebhookSignature(raw, signature, secret);

    if (!valid && process.env.NODE_ENV === 'production') {
      throw new BadRequestException('Invalid cryptographic webhook signature');
    }

    return { received: true, verified: valid };
  }
}


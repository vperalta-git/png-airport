import { ApiProperty } from '@nestjs/swagger';

export class WhatsAppOtpRequestDto {
  @ApiProperty({ example: '+675 7123 4567' })
  whatsapp_number: string;
}

export class WhatsAppVerifyDto {
  @ApiProperty({ example: '+675 7123 4567' })
  whatsapp_number: string;

  @ApiProperty({ example: '482910' })
  otp: string;
}


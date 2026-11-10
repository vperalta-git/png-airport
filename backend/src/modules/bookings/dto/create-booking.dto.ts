import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsNumber,
  IsOptional,
  IsArray,
  ValidateNested,
  IsEmail,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  VehicleCategoryEnum,
  SecurityEscortTypeEnum,
  TransferDirectionEnum,
} from '../../quotations/dto/create-quote.dto';

export class PassengerManifestItemDto {
  @ApiProperty({ example: 'David O\'Connor' })
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @ApiPropertyOptional({ example: '+675 7234 9876' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'david.o@miningpng.com.pg' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: 'PP-A8920194', description: 'Passport or National ID' })
  @IsOptional()
  @IsString()
  idDocumentNumber?: string;

  @ApiPropertyOptional({ example: '2 pieces of standard luggage' })
  @IsOptional()
  @IsString()
  luggageNotes?: string;
}

export class CreateBookingRequestDto {
  @ApiProperty({ example: 'airport_nadzab_lae' })
  @IsString()
  @IsNotEmpty()
  airportId: string;

  @ApiProperty({ enum: TransferDirectionEnum, example: TransferDirectionEnum.INBOUND_AIRPORT_TO_CITY })
  @IsEnum(TransferDirectionEnum)
  direction: TransferDirectionEnum;

  @ApiProperty({ enum: VehicleCategoryEnum, example: VehicleCategoryEnum.HEAVY_4WD })
  @IsEnum(VehicleCategoryEnum)
  vehicleCategory: VehicleCategoryEnum;

  @ApiProperty({ enum: SecurityEscortTypeEnum, example: SecurityEscortTypeEnum.ARMED_ESCORT_CHASE_VEHICLE })
  @IsEnum(SecurityEscortTypeEnum)
  securityEscortType: SecurityEscortTypeEnum;

  @ApiProperty({ example: '2026-11-15T09:30:00.000Z' })
  @IsString()
  pickupDateTime: string;

  @ApiProperty({ example: 'PX 102' })
  @IsOptional()
  @IsString()
  flightNumber?: string;

  @ApiProperty({ example: 'Lae International Hotel, 4th St, Lae' })
  @IsString()
  @IsNotEmpty()
  destinationAddress: string;

  @ApiPropertyOptional({ example: 'Nadzab Terminal Curbside Staging Bay 2' })
  @IsOptional()
  @IsString()
  pickupLocationDetail?: string;

  @ApiPropertyOptional({ example: 'QUO-A1B2C3D4' })
  @IsOptional()
  @IsString()
  quotationId?: string;

  @ApiPropertyOptional({ example: 'corp_mining_png' })
  @IsOptional()
  @IsString()
  corporateAccountId?: string;

  @ApiPropertyOptional({ example: 'PO-2026-PNG-4491' })
  @IsOptional()
  @IsString()
  purchaseOrderNumber?: string;

  @ApiProperty({ type: [PassengerManifestItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PassengerManifestItemDto)
  passengers: PassengerManifestItemDto[];

  @ApiPropertyOptional({ example: 'VIP minerals delegation; ensure armed guard on convoy.' })
  @IsOptional()
  @IsString()
  specialInstructions?: string;
}

export class ConfirmBookingDto {
  @ApiProperty({ example: 'CARD_GATEWAY', enum: ['CASH_ON_BOARD', 'BANK_TRANSFER_BSP', 'CARD_GATEWAY', 'CORPORATE_CREDIT'] })
  @IsString()
  paymentMethod: 'CASH_ON_BOARD' | 'BANK_TRANSFER_BSP' | 'CARD_GATEWAY' | 'CORPORATE_CREDIT';

  @ApiPropertyOptional({ example: 'TXN-BSP-991823901' })
  @IsOptional()
  @IsString()
  paymentReference?: string;
}


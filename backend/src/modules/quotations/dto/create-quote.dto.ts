import { IsString, IsNotEmpty, IsEnum, IsNumber, IsOptional, Min, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum VehicleCategoryEnum {
  STANDARD_SEDAN = 'STANDARD_SEDAN',
  EXECUTIVE_SUV = 'EXECUTIVE_SUV',
  HEAVY_4WD = 'HEAVY_4WD', // Toyota LandCruiser 79
  ARMORED_SUV = 'ARMORED_SUV', // Armored Toyota Prado B6
  COASTER_BUS = 'COASTER_BUS', // 22-seater passenger bus
}

export enum SecurityEscortTypeEnum {
  NONE = 'NONE',
  STATIC_OFFICER = 'STATIC_OFFICER', // Onboard security officer
  ARMED_ESCORT_CHASE_VEHICLE = 'ARMED_ESCORT_CHASE_VEHICLE', // Separate armed security chase car
  CLOSE_PROTECTION_CONVOY = 'CLOSE_PROTECTION_CONVOY', // Lead + Chase armed security convoy
}

export enum TransferDirectionEnum {
  INBOUND_AIRPORT_TO_CITY = 'INBOUND_AIRPORT_TO_CITY',
  OUTBOUND_CITY_TO_AIRPORT = 'OUTBOUND_CITY_TO_AIRPORT',
  INTERCITY_TRANSFER = 'INTERCITY_TRANSFER',
}

export class CreateQuoteDto {
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
  @IsDateString()
  pickupDateTime: string;

  @ApiProperty({ example: 'Lae International Hotel, 4th St, Lae, Morobe Province' })
  @IsString()
  @IsNotEmpty()
  destinationAddress: string;

  @ApiPropertyOptional({ example: 42.5, description: 'Estimated distance in kilometers' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  estimatedDistanceKm?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  passengerCount?: number;

  @ApiPropertyOptional({ example: 'corp_mining_png' })
  @IsOptional()
  @IsString()
  corporateAccountId?: string;
}


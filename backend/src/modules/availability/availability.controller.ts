import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AvailabilityService, AvailabilityCheckResult } from './availability.service';
import { VehicleCategoryEnum, SecurityEscortTypeEnum } from '../quotations/dto/create-quote.dto';
import { IsEnum, IsDateString, IsOptional, IsNumber } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CheckAvailabilityDto {
  @ApiProperty({ enum: VehicleCategoryEnum, example: VehicleCategoryEnum.HEAVY_4WD })
  @IsEnum(VehicleCategoryEnum)
  vehicleCategory: VehicleCategoryEnum;

  @ApiProperty({ enum: SecurityEscortTypeEnum, example: SecurityEscortTypeEnum.ARMED_ESCORT_CHASE_VEHICLE })
  @IsEnum(SecurityEscortTypeEnum)
  securityEscortType: SecurityEscortTypeEnum;

  @ApiProperty({ example: '2026-11-15T09:30:00.000Z' })
  @IsDateString()
  pickupDateTime: string;

  @ApiProperty({ example: 42.0, required: false })
  @IsOptional()
  @IsNumber()
  estimatedDistanceKm?: number;
}

@ApiTags('Availability')
@Controller('availability')
export class AvailabilityController {
  constructor(private readonly availabilityService: AvailabilityService) {}

  @Post('check')
  @ApiOperation({ summary: 'Check real-time conflict-free availability of vehicles, drivers, and armed guards' })
  @ApiResponse({ status: 200, description: 'Availability evaluated without conflict' })
  async checkAvailability(@Body() dto: CheckAvailabilityDto): Promise<AvailabilityCheckResult> {
    return this.availabilityService.checkAvailability(
      dto.vehicleCategory,
      dto.securityEscortType,
      dto.pickupDateTime,
      dto.estimatedDistanceKm,
    );
  }
}


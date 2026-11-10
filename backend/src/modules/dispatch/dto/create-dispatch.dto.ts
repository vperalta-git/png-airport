import { IsString, IsNotEmpty, IsOptional, IsArray, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AssignDispatchDto {
  @ApiProperty({ example: 'veh_toyota_lc79_01' })
  @IsString()
  @IsNotEmpty()
  vehicleId: string;

  @ApiProperty({ example: 'driver_john_kandep' })
  @IsString()
  @IsNotEmpty()
  driverId: string;

  @ApiPropertyOptional({ example: 'guard_michael_toru' })
  @IsOptional()
  @IsString()
  securityGuardId?: string;

  @ApiPropertyOptional({ example: 'Lead escort on Highlands Highway sector' })
  @IsOptional()
  @IsString()
  operationalNotes?: string;
}

export class PreTripInspectionDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  tiresAndSparesInspected: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  fuelSufficient: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  vhfRadioTested: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  firstAidTraumaKitPresent: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  exteriorCleanAndServiceable: boolean;

  @ApiPropertyOptional({ example: 'All checklists cleared; departing base staging.' })
  @IsOptional()
  @IsString()
  notes?: string;
}


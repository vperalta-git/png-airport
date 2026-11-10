import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AirportsService, AirportEntity } from './airports.service';

@ApiTags('Airports')
@Controller('airports')
export class AirportsController {
  constructor(private readonly airportsService: AirportsService) {}

  @Get()
  @ApiOperation({ summary: 'List all active commercial airports and geofences in PNG' })
  @ApiResponse({ status: 200, description: 'List of airports returned successfully.' })
  async getAirports(): Promise<AirportEntity[]> {
    return this.airportsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get airport details and pickup staging zones by ID or IATA/ICAO code' })
  @ApiResponse({ status: 200, description: 'Airport details found.' })
  @ApiResponse({ status: 404, description: 'Airport not found.' })
  async getAirport(@Param('id') id: string): Promise<AirportEntity> {
    return this.airportsService.findById(id);
  }
}


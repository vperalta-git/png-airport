import { Controller, Get, Param, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { FlightsService, FlightTrackingRecord } from './flights.service';

@ApiTags('Flights')
@Controller('flights')
export class FlightsController {
  constructor(private readonly flightsService: FlightsService) {}

  @Get(':flightNumber')
  @ApiOperation({ summary: 'Look up real-time flight radar tracking status (Air Niugini / PNG Air)' })
  @ApiResponse({ status: 200, description: 'Flight status retrieved.' })
  async getFlight(@Param('flightNumber') flightNumber: string): Promise<FlightTrackingRecord> {
    return this.flightsService.getFlightStatus(flightNumber);
  }

  @Post(':flightNumber/delay')
  @ApiOperation({ summary: 'Update flight delay and recalculate airport staging triggers' })
  async updateDelay(
    @Param('flightNumber') flightNumber: string,
    @Body('delayMinutes') delayMinutes: number,
    @Body('reason') reason?: string,
  ): Promise<FlightTrackingRecord> {
    return this.flightsService.updateFlightDelay(flightNumber, delayMinutes, reason);
  }
}


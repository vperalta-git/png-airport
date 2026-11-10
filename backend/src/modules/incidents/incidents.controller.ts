import { Controller, Post, Body, Get, Param, Patch } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { IncidentsService, IncidentReportDto, IncidentEntity } from './incidents.service';

@ApiTags('Incidents')
@Controller('incidents')
export class IncidentsController {
  constructor(private readonly incidentsService: IncidentsService) {}

  @Post('report')
  @ApiOperation({ summary: 'Submit an emergency SOS or operational incident report (P1 to P4)' })
  async reportIncident(@Body() dto: IncidentReportDto): Promise<IncidentEntity> {
    return this.incidentsService.reportIncident(dto);
  }

  @Get('active')
  @ApiOperation({ summary: 'List all active emergency incidents for Control Room situational awareness' })
  async getActiveIncidents(): Promise<IncidentEntity[]> {
    return this.incidentsService.listActiveIncidents();
  }

  @Patch(':id/resolve')
  @ApiOperation({ summary: 'Close and resolve an incident report with post-incident notes' })
  async resolveIncident(
    @Param('id') id: string,
    @Body('resolutionNotes') notes: string,
    @Body('resolverId') resolverId: string,
  ): Promise<IncidentEntity> {
    return this.incidentsService.resolveIncident(id, notes, resolverId);
  }
}


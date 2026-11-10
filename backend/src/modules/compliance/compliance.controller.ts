import { Controller, Get, Post } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ComplianceService, ComplianceAuditReport } from './compliance.service';

@ApiTags('Compliance')
@Controller('compliance')
export class ComplianceController {
  constructor(private readonly complianceService: ComplianceService) {}

  @Get('audit')
  @ApiOperation({ summary: 'Run real-time compliance audit across vehicles, drivers, and security permits' })
  @ApiResponse({ status: 200, description: 'Compliance audit generated.' })
  async getAudit(): Promise<ComplianceAuditReport> {
    return this.complianceService.runFullComplianceAudit();
  }

  @Post('run-check')
  @ApiOperation({ summary: 'Trigger scheduled compliance sweep and log expiry warnings' })
  async triggerSweep(): Promise<ComplianceAuditReport> {
    return this.complianceService.runFullComplianceAudit();
  }
}


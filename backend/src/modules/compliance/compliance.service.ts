import { Injectable, Logger } from '@nestjs/common';
import { FirebaseService } from '../../firebase/firebase.service';
import { ResourcesService } from '../resources/resources.service';

export interface ComplianceAuditReport {
  timestamp: string;
  totalVehiclesAudited: number;
  vehiclesExpiredRoadworthy: string[];
  totalDriversAudited: number;
  driversExpiredLicense: string[];
  totalGuardsAudited: number;
  guardsExpiredPermits: string[];
  complianceScorePercent: number;
}

@Injectable()
export class ComplianceService {
  private readonly logger = new Logger(ComplianceService.name);
  private readonly complianceCollection = 'compliance_alerts';

  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly resourcesService: ResourcesService,
  ) {}

  async runFullComplianceAudit(): Promise<ComplianceAuditReport> {
    const now = Date.now();
    const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;

    const vehicles = await this.resourcesService.listVehicles();
    const drivers = await this.resourcesService.listDrivers();
    const guards = await this.resourcesService.listSecurityPersonnel();

    const expiredVehicles: string[] = [];
    const expiredDrivers: string[] = [];
    const expiredGuards: string[] = [];

    // Audit Vehicles
    for (const v of vehicles) {
      const rwTime = new Date(v.roadworthyExpiry).getTime();
      if (rwTime < now) {
        expiredVehicles.push(`${v.registrationPlate} (Roadworthy expired ${v.roadworthyExpiry})`);
      }
    }

    // Audit Drivers
    for (const d of drivers) {
      const licTime = new Date(d.licenseExpiry).getTime();
      if (licTime < now) {
        expiredDrivers.push(`${d.fullName} (License expired ${d.licenseExpiry})`);
      }
    }

    // Audit Security Guards
    for (const g of guards) {
      const faTime = new Date(g.firearmPermitExpiry).getTime();
      if (faTime < now) {
        expiredGuards.push(`${g.fullName} (Firearm permit expired ${g.firearmPermitExpiry})`);
      }
    }

    const totalAssets = vehicles.length + drivers.length + guards.length;
    const totalDefects = expiredVehicles.length + expiredDrivers.length + expiredGuards.length;
    const score = totalAssets > 0 ? Math.round(((totalAssets - totalDefects) / totalAssets) * 100) : 100;

    const report: ComplianceAuditReport = {
      timestamp: new Date().toISOString(),
      totalVehiclesAudited: vehicles.length,
      vehiclesExpiredRoadworthy: expiredVehicles,
      totalDriversAudited: drivers.length,
      driversExpiredLicense: expiredDrivers,
      totalGuardsAudited: guards.length,
      guardsExpiredPermits: expiredGuards,
      complianceScorePercent: score,
    };

    if (totalDefects > 0) {
      this.logger.warn(`Compliance audit found ${totalDefects} defects! Score: ${score}%`);
    } else {
      this.logger.log(`Compliance audit passed with 100% compliance across all assets.`);
    }

    return report;
  }
}


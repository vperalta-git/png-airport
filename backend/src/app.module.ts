import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { APP_GUARD } from "@nestjs/core";
import { FoundationGuard } from "./common/guards/foundation.guard";
import { FirebaseAuthGuard } from "./common/guards/auth.guard";
import { RolesGuard } from "./common/guards/roles.guard";
import { ContractsController } from "./contracts/contracts.controller";
import { ConfigController } from "./config/config.controller";
import { FirebaseModule } from "./firebase/firebase.module";
import { HealthController } from "./health.controller";
import { AirportsModule } from "./modules/airports/airports.module";
import { AuthModule } from "./modules/auth/auth.module";
import { QuotationsModule } from "./modules/quotations/quotations.module";
import { ResourcesModule } from "./modules/resources/resources.module";
import { AvailabilityModule } from "./modules/availability/availability.module";
import { BookingsModule } from "./modules/bookings/bookings.module";
import { DispatchModule } from "./modules/dispatch/dispatch.module";
import { FlightsModule } from "./modules/flights/flights.module";
import { TripsModule } from "./modules/trips/trips.module";
import { IncidentsModule } from "./modules/incidents/incidents.module";
import { PaymentsModule } from "./modules/payments/payments.module";
import { ComplianceModule } from "./modules/compliance/compliance.module";
import { ReportsModule } from "./modules/reports/reports.module";
import { OfflineSyncModule } from "./modules/offline-sync/offline-sync.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    FirebaseModule,
    AuthModule,
    AirportsModule,
    QuotationsModule,
    ResourcesModule,
    AvailabilityModule,
    BookingsModule,
    DispatchModule,
    FlightsModule,
    TripsModule,
    IncidentsModule,
    PaymentsModule,
    ComplianceModule,
    ReportsModule,
    OfflineSyncModule,
  ],
  controllers: [HealthController, ContractsController, ConfigController],
  providers: [
    { provide: APP_GUARD, useClass: FoundationGuard },
    { provide: APP_GUARD, useClass: FirebaseAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}

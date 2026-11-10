import { Module } from '@nestjs/common';
import { OfflineSyncService } from './offline-sync.service';
import { OfflineSyncController } from './offline-sync.controller';
import { BookingsModule } from '../bookings/bookings.module';
import { TripsModule } from '../trips/trips.module';

@Module({
  imports: [BookingsModule, TripsModule],
  providers: [OfflineSyncService],
  controllers: [OfflineSyncController],
  exports: [OfflineSyncService],
})
export class OfflineSyncModule {}


import { Module } from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { QuotationsModule } from '../quotations/quotations.module';
import { AvailabilityModule } from '../availability/availability.module';
import { ResourcesModule } from '../resources/resources.module';

@Module({
  imports: [QuotationsModule, AvailabilityModule, ResourcesModule],
  providers: [BookingsService],
  controllers: [BookingsController],
  exports: [BookingsService],
})
export class BookingsModule {}


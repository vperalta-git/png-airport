import { Module } from '@nestjs/common';
import { FlightsService } from './flights.service';
import { FlightsController } from './flights.controller';
import { BookingsModule } from '../bookings/bookings.module';

@Module({
  imports: [BookingsModule],
  providers: [FlightsService],
  controllers: [FlightsController],
  exports: [FlightsService],
})
export class FlightsModule {}


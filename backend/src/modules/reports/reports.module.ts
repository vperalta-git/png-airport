import { Module } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { ReportsController } from './reports.controller';
import { BookingsModule } from '../bookings/bookings.module';
import { ResourcesModule } from '../resources/resources.module';

@Module({
  imports: [BookingsModule, ResourcesModule],
  providers: [ReportsService],
  controllers: [ReportsController],
  exports: [ReportsService],
})
export class ReportsModule {}


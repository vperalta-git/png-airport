import { Module } from '@nestjs/common';
import { DispatchService } from './dispatch.service';
import { DispatchController } from './dispatch.controller';
import { BookingsModule } from '../bookings/bookings.module';
import { ResourcesModule } from '../resources/resources.module';

@Module({
  imports: [BookingsModule, ResourcesModule],
  providers: [DispatchService],
  controllers: [DispatchController],
  exports: [DispatchService],
})
export class DispatchModule {}


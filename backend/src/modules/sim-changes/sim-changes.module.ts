import { Module } from '@nestjs/common';

import { DevicesModule } from '../devices/devices.module';
import { SimChangesController } from './sim-changes.controller';
import { SimChangesService } from './sim-changes.service';

@Module({
  imports: [DevicesModule],
  controllers: [SimChangesController],
  providers: [SimChangesService],
  exports: [SimChangesService],
})
export class SimChangesModule {}

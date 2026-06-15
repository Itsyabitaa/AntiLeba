import { Module } from '@nestjs/common';

import { DevicesModule } from '../devices/devices.module';
import { PhotoStorageService } from './photo-storage.service';
import { PhotosController } from './photos.controller';
import { PhotosService } from './photos.service';

@Module({
  imports: [DevicesModule],
  controllers: [PhotosController],
  providers: [PhotosService, PhotoStorageService],
  exports: [PhotosService],
})
export class PhotosModule {}

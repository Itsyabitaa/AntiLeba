import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Photo } from '@prisma/client';
import { memoryStorage } from 'multer';

import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthUser } from '../auth/types/auth-user.type';
import { UploadPhotoDto } from './dto/upload-photo.dto';
import { PhotosService } from './photos.service';

@Controller('photos')
export class PhotosController {
  constructor(private readonly photos: PhotosService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  upload(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadPhotoDto,
  ): Promise<Photo> {
    return this.photos.upload(user.id, dto, file);
  }

  @Get()
  list(
    @CurrentUser() user: AuthUser,
    @Query('deviceId', ParseUUIDPipe) deviceId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ): Promise<Photo[]> {
    return this.photos.findByDevice(user.id, deviceId, limit);
  }
}

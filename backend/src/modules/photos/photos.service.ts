import { BadRequestException, Injectable } from '@nestjs/common';
import { Photo, PhotoTrigger } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';
import { PhotoTriggerDto, UploadPhotoDto } from './dto/upload-photo.dto';
import { PhotoStorageService } from './photo-storage.service';

@Injectable()
export class PhotosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
    private readonly storage: PhotoStorageService,
  ) {}

  async upload(
    userId: string,
    dto: UploadPhotoDto,
    file: Express.Multer.File | undefined,
  ): Promise<Photo> {
    if (!file || !file.buffer?.length) {
      throw new BadRequestException('Photo file is required');
    }

    await this.devices.findByIdForUser(dto.deviceId, userId);

    if (dto.clientEventId) {
      const existing = await this.prisma.photo.findUnique({
        where: {
          deviceId_clientEventId: {
            deviceId: dto.deviceId,
            clientEventId: dto.clientEventId,
          },
        },
      });
      if (existing) return existing;
    }

    const extension = this.extensionForMime(file.mimetype);
    const filename = `${dto.clientEventId ?? Date.now()}.${extension}`;
    const storagePath = await this.storage.save(
      userId,
      dto.deviceId,
      filename,
      file.buffer,
    );

    const photo = await this.prisma.photo.create({
      data: {
        deviceId: dto.deviceId,
        clientEventId: dto.clientEventId,
        trigger: this.toPrismaTrigger(dto.trigger),
        storagePath,
        mimeType: file.mimetype || 'image/jpeg',
        fileSize: file.size,
        capturedAt: new Date(dto.capturedAt),
      },
    });

    await this.devices.touchLastSeen(dto.deviceId, userId);
    return photo;
  }

  async findByDevice(
    userId: string,
    deviceId: string,
    limit = 50,
  ): Promise<Photo[]> {
    await this.devices.findByIdForUser(deviceId, userId);
    const take = Math.min(Math.max(limit, 1), 200);
    return this.prisma.photo.findMany({
      where: { deviceId },
      orderBy: { capturedAt: 'desc' },
      take,
    });
  }

  private extensionForMime(mime: string): string {
    switch (mime) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }

  private toPrismaTrigger(trigger: PhotoTriggerDto): PhotoTrigger {
    return trigger as PhotoTrigger;
  }
}

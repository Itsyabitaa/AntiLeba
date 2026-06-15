import { Injectable } from '@nestjs/common';
import { Location, Prisma } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';
import {
  BatchUploadResult,
  CreateLocationDto,
} from './dto/create-location.dto';

@Injectable()
export class LocationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
  ) {}

  async create(userId: string, dto: CreateLocationDto): Promise<Location> {
    await this.devices.findByIdForUser(dto.deviceId, userId);

    if (dto.clientEventId) {
      const existing = await this.prisma.location.findUnique({
        where: {
          deviceId_clientEventId: {
            deviceId: dto.deviceId,
            clientEventId: dto.clientEventId,
          },
        },
      });
      if (existing) return existing;
    }

    const location = await this.prisma.location.create({
      data: this.toCreateInput(dto),
    });

    await this.devices.touchLastSeen(dto.deviceId, userId);
    return location;
  }

  async createBatch(
    userId: string,
    dtos: CreateLocationDto[],
  ): Promise<BatchUploadResult> {
    const deviceIds = [...new Set(dtos.map((dto) => dto.deviceId))];
    for (const deviceId of deviceIds) {
      await this.devices.findByIdForUser(deviceId, userId);
    }

    const locations: Location[] = [];
    let inserted = 0;
    let skipped = 0;

    for (const dto of dtos) {
      const result = await this.upsertLocation(dto);
      locations.push(result.location);
      if (result.skipped) {
        skipped += 1;
      } else {
        inserted += 1;
      }
    }

    for (const deviceId of deviceIds) {
      await this.devices.touchLastSeen(deviceId, userId);
    }

    return { inserted, skipped, locations };
  }

  async findByDevice(
    userId: string,
    deviceId: string,
    limit = 50,
  ): Promise<Location[]> {
    await this.devices.findByIdForUser(deviceId, userId);
    const take = Math.min(Math.max(limit, 1), 200);
    return this.prisma.location.findMany({
      where: { deviceId },
      orderBy: { recordedAt: 'desc' },
      take,
    });
  }

  private async upsertLocation(
    dto: CreateLocationDto,
  ): Promise<{ location: Location; skipped: boolean }> {
    if (dto.clientEventId) {
      const existing = await this.prisma.location.findUnique({
        where: {
          deviceId_clientEventId: {
            deviceId: dto.deviceId,
            clientEventId: dto.clientEventId,
          },
        },
      });
      if (existing) {
        return { location: existing, skipped: true };
      }
    }

    try {
      const location = await this.prisma.location.create({
        data: this.toCreateInput(dto),
      });
      return { location, skipped: false };
    } catch (error) {
      if (
        dto.clientEventId &&
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const existing = await this.prisma.location.findUnique({
          where: {
            deviceId_clientEventId: {
              deviceId: dto.deviceId,
              clientEventId: dto.clientEventId,
            },
          },
        });
        if (existing) {
          return { location: existing, skipped: true };
        }
      }
      throw error;
    }
  }

  private toCreateInput(dto: CreateLocationDto): Prisma.LocationCreateInput {
    return {
      device: { connect: { id: dto.deviceId } },
      clientEventId: dto.clientEventId,
      latitude: dto.latitude,
      longitude: dto.longitude,
      accuracy: dto.accuracy,
      altitude: dto.altitude,
      speed: dto.speed,
      heading: dto.heading,
      recordedAt: new Date(dto.recordedAt),
    };
  }
}

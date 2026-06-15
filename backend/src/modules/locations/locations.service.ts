import { Injectable } from '@nestjs/common';
import { Location, Prisma } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';
import { CreateLocationDto } from './dto/create-location.dto';

@Injectable()
export class LocationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
  ) {}

  async create(userId: string, dto: CreateLocationDto): Promise<Location> {
    await this.devices.findByIdForUser(dto.deviceId, userId);

    const location = await this.prisma.location.create({
      data: this.toCreateInput(dto),
    });

    await this.devices.touchLastSeen(dto.deviceId, userId);
    return location;
  }

  async createBatch(
    userId: string,
    dtos: CreateLocationDto[],
  ): Promise<{ count: number; locations: Location[] }> {
    const deviceIds = [...new Set(dtos.map((dto) => dto.deviceId))];
    for (const deviceId of deviceIds) {
      await this.devices.findByIdForUser(deviceId, userId);
    }

    const locations = await this.prisma.$transaction(
      dtos.map((dto) =>
        this.prisma.location.create({ data: this.toCreateInput(dto) }),
      ),
    );

    for (const deviceId of deviceIds) {
      await this.devices.touchLastSeen(deviceId, userId);
    }

    return { count: locations.length, locations };
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

  private toCreateInput(dto: CreateLocationDto): Prisma.LocationCreateInput {
    return {
      device: { connect: { id: dto.deviceId } },
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

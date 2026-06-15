import { Injectable } from '@nestjs/common';
import { DeviceStatus, SimChange } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';
import { ReportSimChangeDto } from './dto/report-sim-change.dto';

@Injectable()
export class SimChangesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
  ) {}

  async report(userId: string, dto: ReportSimChangeDto): Promise<SimChange> {
    await this.devices.findByIdForUser(dto.deviceId, userId);

    if (dto.clientEventId) {
      const existing = await this.prisma.simChange.findUnique({
        where: {
          deviceId_clientEventId: {
            deviceId: dto.deviceId,
            clientEventId: dto.clientEventId,
          },
        },
      });
      if (existing) return existing;
    }

    const simChange = await this.prisma.$transaction(async (tx) => {
      const created = await tx.simChange.create({
        data: {
          deviceId: dto.deviceId,
          clientEventId: dto.clientEventId,
          previousSerial: dto.previousSerial,
          newSerial: dto.newSerial,
          previousOperator: dto.previousOperator,
          newOperator: dto.newOperator,
          detectedAt: new Date(dto.detectedAt),
        },
      });

      await tx.device.update({
        where: { id: dto.deviceId },
        data: {
          simSerial: dto.newSerial,
          simOperator: dto.newOperator,
          status: DeviceStatus.LOST,
          lastSeenAt: new Date(),
        },
      });

      return created;
    });

    return simChange;
  }

  async findByDevice(
    userId: string,
    deviceId: string,
    limit = 50,
  ): Promise<SimChange[]> {
    await this.devices.findByIdForUser(deviceId, userId);
    const take = Math.min(Math.max(limit, 1), 200);
    return this.prisma.simChange.findMany({
      where: { deviceId },
      orderBy: { detectedAt: 'desc' },
      take,
    });
  }
}

import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Device, DeviceStatus } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { SessionsService } from '../sessions/sessions.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Injectable()
export class DevicesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sessions: SessionsService,
  ) {}

  findAllForUser(userId: string): Promise<Device[]> {
    return this.prisma.device.findMany({
      where: { userId },
      orderBy: { enrolledAt: 'desc' },
    });
  }

  findByIdForUser(id: string, userId: string): Promise<Device> {
    return this.prisma.device.findFirst({ where: { id, userId } }).then((device) => {
      if (!device) throw new NotFoundException('Device not found');
      return device;
    });
  }

  async register(
    userId: string,
    dto: RegisterDeviceDto,
    sessionId?: string,
  ): Promise<Device> {
    const existing = await this.prisma.device.findUnique({
      where: { deviceUid: dto.deviceUid },
    });

    if (existing && existing.userId !== userId) {
      throw new ConflictException('Device is already enrolled to another account');
    }

    const data = {
      label: dto.label,
      manufacturer: dto.manufacturer,
      model: dto.model,
      osVersion: dto.osVersion,
      appVersion: dto.appVersion,
      simSerial: dto.simSerial,
      simOperator: dto.simOperator,
      pushToken: dto.pushToken,
      status: DeviceStatus.ACTIVE,
      lastSeenAt: new Date(),
    };

    const device = existing
      ? await this.prisma.device.update({
          where: { id: existing.id },
          data,
        })
      : await this.prisma.device.create({
          data: {
            userId,
            deviceUid: dto.deviceUid,
            ...data,
          },
        });

    if (sessionId) {
      const session = await this.sessions.findActive(sessionId);
      if (session && session.userId === userId) {
        await this.sessions.linkDevice(sessionId, device.id);
      }
    }

    return device;
  }

  async touchLastSeen(deviceId: string, userId: string): Promise<Device> {
    const device = await this.findByIdForUser(deviceId, userId);
    return this.prisma.device.update({
      where: { id: device.id },
      data: { lastSeenAt: new Date() },
    });
  }

  assertOwnership(device: Device, userId: string): void {
    if (device.userId !== userId) {
      throw new ForbiddenException('You do not own this device');
    }
  }
}

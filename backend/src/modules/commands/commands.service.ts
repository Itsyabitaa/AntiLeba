import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  Command,
  CommandStatus,
  CommandType,
  DeviceStatus,
} from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';
import { AckCommandDto } from './dto/ack-command.dto';
import { IssueCommandDto } from './dto/issue-command.dto';

export interface CommandPayload {
  id: string;
  deviceId: string;
  type: CommandType;
  payload: Record<string, unknown> | null;
  issuedAt: string;
}

@Injectable()
export class CommandsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
  ) {}

  async issue(userId: string, dto: IssueCommandDto): Promise<Command> {
    await this.devices.findByIdForUser(dto.deviceId, userId);

    if (dto.clientEventId) {
      const existing = await this.prisma.command.findUnique({
        where: {
          deviceId_clientEventId: {
            deviceId: dto.deviceId,
            clientEventId: dto.clientEventId,
          },
        },
      });
      if (existing) return existing;
    }

    const command = await this.prisma.$transaction(async (tx) => {
      const created = await tx.command.create({
        data: {
          deviceId: dto.deviceId,
          issuedById: userId,
          clientEventId: dto.clientEventId,
          type: dto.type,
          status: CommandStatus.PENDING,
          payload: dto.payload ?? undefined,
        },
      });

      if (dto.type === CommandType.ACTIVATE_THEFT_MODE) {
        await tx.device.update({
          where: { id: dto.deviceId },
          data: {
            status: DeviceStatus.LOST,
            lastSeenAt: new Date(),
          },
        });
      }

      return created;
    });

    await this.devices.touchLastSeen(dto.deviceId, userId);
    return command;
  }

  findByDevice(
    userId: string,
    deviceId: string,
    limit: number,
  ): Promise<Command[]> {
    return this.devices.findByIdForUser(deviceId, userId).then(() =>
      this.prisma.command.findMany({
        where: { deviceId },
        orderBy: { issuedAt: 'desc' },
        take: Math.min(Math.max(limit, 1), 200),
      }),
    );
  }

  findPendingForDevice(deviceId: string): Promise<Command[]> {
    return this.prisma.command.findMany({
      where: {
        deviceId,
        status: { in: [CommandStatus.PENDING, CommandStatus.DELIVERED] },
      },
      orderBy: { issuedAt: 'asc' },
      take: 50,
    });
  }

  async markDelivered(commandId: string, deviceId: string): Promise<Command> {
    const command = await this.prisma.command.findFirst({
      where: { id: commandId, deviceId },
    });
    if (!command) {
      throw new NotFoundException('Command not found');
    }
    if (command.status !== CommandStatus.PENDING) {
      return command;
    }

    return this.prisma.command.update({
      where: { id: commandId },
      data: {
        status: CommandStatus.DELIVERED,
        deliveredAt: new Date(),
      },
    });
  }

  async ack(userId: string, dto: AckCommandDto): Promise<Command> {
    await this.devices.findByIdForUser(dto.deviceId, userId);

    const command = await this.prisma.command.findFirst({
      where: { id: dto.commandId, deviceId: dto.deviceId },
    });
    if (!command) {
      throw new NotFoundException('Command not found');
    }

    if (
      dto.status !== CommandStatus.ACKNOWLEDGED &&
      dto.status !== CommandStatus.FAILED
    ) {
      throw new BadRequestException(
        'Ack status must be ACKNOWLEDGED or FAILED',
      );
    }

    if (
      command.status === CommandStatus.ACKNOWLEDGED ||
      command.status === CommandStatus.FAILED ||
      command.status === CommandStatus.EXPIRED
    ) {
      return command;
    }

    const updated = await this.prisma.command.update({
      where: { id: command.id },
      data: {
        status: dto.status,
        completedAt: new Date(),
        errorMessage: dto.errorMessage,
        deliveredAt: command.deliveredAt ?? new Date(),
      },
    });

    await this.devices.touchLastSeen(dto.deviceId, userId);
    return updated;
  }

  assertDeviceConnection(
    userId: string,
    deviceId: string,
    sessionDeviceId: string | null,
  ): void {
    if (sessionDeviceId && sessionDeviceId !== deviceId) {
      throw new ForbiddenException(
        'Session is bound to a different enrolled device',
      );
    }
  }

  toPayload(command: Command): CommandPayload {
    return {
      id: command.id,
      deviceId: command.deviceId,
      type: command.type,
      payload:
        command.payload && typeof command.payload === 'object'
          ? (command.payload as Record<string, unknown>)
          : null,
      issuedAt: command.issuedAt.toISOString(),
    };
  }
}

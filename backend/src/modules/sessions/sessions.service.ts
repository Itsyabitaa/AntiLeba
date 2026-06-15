import { Injectable } from '@nestjs/common';
import { Session } from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SessionsService {
  constructor(private readonly prisma: PrismaService) {}

  create(userId: string, expiresAt: Date, deviceId?: string): Promise<Session> {
    return this.prisma.session.create({
      data: { userId, expiresAt, deviceId },
    });
  }

  findActive(id: string): Promise<Session | null> {
    return this.prisma.session.findFirst({
      where: {
        id,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
  }

  revoke(id: string): Promise<Session> {
    return this.prisma.session.update({
      where: { id },
      data: { revokedAt: new Date() },
    });
  }

  linkDevice(sessionId: string, deviceId: string): Promise<Session> {
    return this.prisma.session.update({
      where: { id: sessionId },
      data: { deviceId },
    });
  }
}

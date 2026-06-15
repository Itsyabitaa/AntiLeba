import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { Socket } from 'socket.io';

import type { JwtPayload } from '../auth/types/auth-user.type';
import { SessionsService } from '../sessions/sessions.service';
import { UsersService } from '../users/users.service';

export interface WsAuthContext {
  userId: string;
  sessionId: string;
  sessionDeviceId: string | null;
}

@Injectable()
export class WsAuthService {
  constructor(
    private readonly jwt: JwtService,
    private readonly sessions: SessionsService,
    private readonly users: UsersService,
  ) {}

  extractToken(client: Socket): string | null {
    const authToken = client.handshake.auth?.token;
    if (typeof authToken === 'string' && authToken.length > 0) {
      return authToken;
    }

    const header = client.handshake.headers.authorization;
    if (typeof header === 'string' && header.startsWith('Bearer ')) {
      return header.slice('Bearer '.length).trim();
    }

    return null;
  }

  async authenticate(client: Socket): Promise<WsAuthContext> {
    const token = this.extractToken(client);
    if (!token) {
      throw new UnauthorizedException('Missing authentication token');
    }

    let payload: JwtPayload;
    try {
      payload = await this.jwt.verifyAsync<JwtPayload>(token);
    } catch {
      throw new UnauthorizedException('Invalid authentication token');
    }

    const session = await this.sessions.findActive(payload.sid);
    if (!session) {
      throw new UnauthorizedException('Session is no longer valid');
    }

    const user = await this.users.findByIdOrFail(payload.sub).catch(() => null);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Session is no longer valid');
    }

    return {
      userId: user.id,
      sessionId: session.id,
      sessionDeviceId: session.deviceId,
    };
  }
}

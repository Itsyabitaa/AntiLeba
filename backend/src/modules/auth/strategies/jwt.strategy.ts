import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

import { SessionsService } from '../../sessions/sessions.service';
import { UsersService } from '../../users/users.service';
import type { AuthUser, JwtPayload } from '../types/auth-user.type';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    config: ConfigService,
    private readonly users: UsersService,
    private readonly sessions: SessionsService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_SECRET')!,
    });
  }

  async validate(payload: JwtPayload): Promise<AuthUser> {
    const session = await this.sessions.findActive(payload.sid);
    if (!session) {
      throw new UnauthorizedException('Session is no longer valid');
    }

    const user = await this.users.findByIdOrFail(payload.sub).catch(() => null);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Session is no longer valid');
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      sessionId: payload.sid,
    };
  }
}

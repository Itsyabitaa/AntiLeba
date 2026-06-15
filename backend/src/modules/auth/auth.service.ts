import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';

import { SessionsService } from '../sessions/sessions.service';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import type { JwtPayload } from './types/auth-user.type';
import { expiresAtFromConfig } from './utils/jwt-expiry.util';
import * as bcrypt from 'bcrypt';

const BCRYPT_ROUNDS = 12;

export interface AuthResponse {
  accessToken: string;
  user: {
    id: string;
    email: string;
    fullName: string;
    role: User['role'];
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly sessions: SessionsService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResponse> {
    const email = dto.email.toLowerCase();
    const existing = await this.users.findByEmail(email);
    if (existing) {
      throw new ConflictException('Email already in use');
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const user = await this.users.create({
      email,
      passwordHash,
      fullName: dto.fullName,
      phone: dto.phone,
    });

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto): Promise<AuthResponse> {
    const email = dto.email.toLowerCase();
    const user = await this.users.findByEmail(email);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    await this.users.touchLastLogin(user.id);
    return this.buildAuthResponse(user);
  }

  async logout(sessionId: string): Promise<void> {
    const session = await this.sessions.findActive(sessionId);
    if (!session) {
      throw new UnauthorizedException('Session is no longer valid');
    }
    await this.sessions.revoke(sessionId);
  }

  private async buildAuthResponse(user: User): Promise<AuthResponse> {
    const expiresIn = this.config.get<string>('JWT_EXPIRES_IN') ?? '1d';
    const expiresAt = expiresAtFromConfig(expiresIn);
    const session = await this.sessions.create(user.id, expiresAt);

    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      sid: session.id,
    };
    const accessToken = await this.jwt.signAsync(payload);
    return {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
    };
  }
}

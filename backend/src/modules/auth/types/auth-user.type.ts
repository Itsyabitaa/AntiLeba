import { UserRole } from '@prisma/client';

export interface AuthUser {
  id: string;
  email: string;
  role: UserRole;
  sessionId: string;
}

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
  sid: string;
}

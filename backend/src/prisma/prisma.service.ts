import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  onModuleInit(): void {
    // Don't block bootstrap on the DB connection — Prisma lazy-connects on the
    // first query. We still attempt a connect in the background so we can log
    // the outcome (and so /health can report db: down).
    this.$connect()
      .then(() => this.logger.log('Connected to PostgreSQL'))
      .catch((err: unknown) =>
        this.logger.warn(
          `PostgreSQL not reachable on startup: ${
            err instanceof Error ? err.message : String(err)
          }`,
        ),
      );
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}

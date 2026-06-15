import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { validateEnv } from './config/env.validation';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { DevicesModule } from './modules/devices/devices.module';
import { LocationsModule } from './modules/locations/locations.module';
import { SimChangesModule } from './modules/sim-changes/sim-changes.module';
import { PhotosModule } from './modules/photos/photos.module';
import { CommandsModule } from './modules/commands/commands.module';
import { HealthController } from './modules/health/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: validateEnv,
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    DevicesModule,
    LocationsModule,
    SimChangesModule,
    PhotosModule,
    CommandsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}

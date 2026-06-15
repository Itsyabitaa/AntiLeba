import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { DevicesModule } from '../devices/devices.module';
import { SessionsModule } from '../sessions/sessions.module';
import { UsersModule } from '../users/users.module';
import { CommandsController } from './commands.controller';
import { CommandsGateway } from './commands.gateway';
import { CommandsService } from './commands.service';
import { WsAuthService } from './ws-auth.service';

@Module({
  imports: [AuthModule, DevicesModule, SessionsModule, UsersModule],
  controllers: [CommandsController],
  providers: [CommandsService, CommandsGateway, WsAuthService],
  exports: [CommandsService],
})
export class CommandsModule {}

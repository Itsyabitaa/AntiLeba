import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  ParseIntPipe,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { Command } from '@prisma/client';

import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthUser } from '../auth/types/auth-user.type';
import { CommandsGateway } from './commands.gateway';
import { CommandsService } from './commands.service';
import { AckCommandDto } from './dto/ack-command.dto';
import { IssueCommandDto } from './dto/issue-command.dto';

@Controller('commands')
export class CommandsController {
  constructor(
    private readonly commands: CommandsService,
    private readonly gateway: CommandsGateway,
  ) {}

  @Post()
  async issue(
    @CurrentUser() user: AuthUser,
    @Body() dto: IssueCommandDto,
  ): Promise<Command & { delivered: boolean }> {
    const command = await this.commands.issue(user.id, dto);
    const delivered = await this.gateway.deliverPending(
      command.deviceId,
      command.id,
    );
    return { ...command, delivered };
  }

  @Get()
  list(
    @CurrentUser() user: AuthUser,
    @Query('deviceId', ParseUUIDPipe) deviceId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ): Promise<Command[]> {
    return this.commands.findByDevice(user.id, deviceId, limit);
  }

  @Post('ack')
  ack(
    @CurrentUser() user: AuthUser,
    @Body() dto: AckCommandDto,
  ): Promise<Command> {
    return this.commands.ack(user.id, dto);
  }
}

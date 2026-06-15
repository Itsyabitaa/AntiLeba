import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { Device } from '@prisma/client';

import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthUser } from '../auth/types/auth-user.type';
import { DevicesService } from './devices.service';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { UpdateDeviceStatusDto } from './dto/update-device-status.dto';

@Controller('devices')
export class DevicesController {
  constructor(private readonly devices: DevicesService) {}

  @Get()
  list(@CurrentUser() user: AuthUser): Promise<Device[]> {
    return this.devices.findAllForUser(user.id);
  }

  @Get(':id')
  getOne(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<Device> {
    return this.devices.findByIdForUser(id, user.id);
  }

  @Post('register')
  register(
    @CurrentUser() user: AuthUser,
    @Body() dto: RegisterDeviceDto,
  ): Promise<Device> {
    return this.devices.register(user.id, dto, user.sessionId);
  }

  @Patch(':id/status')
  updateStatus(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateDeviceStatusDto,
  ): Promise<Device> {
    return this.devices.updateStatus(id, user.id, dto.status);
  }
}

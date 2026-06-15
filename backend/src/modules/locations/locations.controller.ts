import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  DefaultValuePipe,
  ParseIntPipe,
  ParseUUIDPipe,
} from '@nestjs/common';
import { Location } from '@prisma/client';

import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthUser } from '../auth/types/auth-user.type';
import {
  BatchCreateLocationsDto,
  BatchUploadResult,
  CreateLocationDto,
} from './dto/create-location.dto';
import { LocationsService } from './locations.service';

@Controller('locations')
export class LocationsController {
  constructor(private readonly locations: LocationsService) {}

  @Post()
  create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateLocationDto,
  ): Promise<Location> {
    return this.locations.create(user.id, dto);
  }

  @Post('batch')
  createBatch(
    @CurrentUser() user: AuthUser,
    @Body() dto: BatchCreateLocationsDto,
  ): Promise<BatchUploadResult> {
    return this.locations.createBatch(user.id, dto.locations);
  }

  @Get()
  list(
    @CurrentUser() user: AuthUser,
    @Query('deviceId', ParseUUIDPipe) deviceId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ): Promise<Location[]> {
    return this.locations.findByDevice(user.id, deviceId, limit);
  }
}

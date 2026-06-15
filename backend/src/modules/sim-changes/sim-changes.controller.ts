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
import { SimChange } from '@prisma/client';

import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthUser } from '../auth/types/auth-user.type';
import { ReportSimChangeDto } from './dto/report-sim-change.dto';
import { SimChangesService } from './sim-changes.service';

@Controller('sim-changes')
export class SimChangesController {
  constructor(private readonly simChanges: SimChangesService) {}

  @Post()
  report(
    @CurrentUser() user: AuthUser,
    @Body() dto: ReportSimChangeDto,
  ): Promise<SimChange> {
    return this.simChanges.report(user.id, dto);
  }

  @Get()
  list(
    @CurrentUser() user: AuthUser,
    @Query('deviceId', ParseUUIDPipe) deviceId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ): Promise<SimChange[]> {
    return this.simChanges.findByDevice(user.id, deviceId, limit);
  }
}

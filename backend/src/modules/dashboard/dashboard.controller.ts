import {
  Controller,
  DefaultValuePipe,
  Get,
  ParseIntPipe,
  Query,
} from '@nestjs/common';

import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthUser } from '../auth/types/auth-user.type';
import {
  DashboardAlert,
  DashboardOverview,
  DashboardService,
  DashboardStats,
} from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboard: DashboardService) {}

  @Get('overview')
  overview(@CurrentUser() user: AuthUser): Promise<DashboardOverview> {
    return this.dashboard.getOverview(user.id);
  }

  @Get('stats')
  stats(@CurrentUser() user: AuthUser): Promise<DashboardStats> {
    return this.dashboard.getStats(user.id);
  }

  @Get('alerts')
  alerts(
    @CurrentUser() user: AuthUser,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ): Promise<DashboardAlert[]> {
    return this.dashboard.getAlerts(user.id, limit);
  }
}

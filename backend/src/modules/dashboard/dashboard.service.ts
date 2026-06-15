import { Injectable } from '@nestjs/common';
import {
  Command,
  CommandType,
  Device,
  DeviceStatus,
  Location,
  SimChange,
} from '@prisma/client';

import { PrismaService } from '../../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';

export type AlertSeverity = 'info' | 'warning' | 'critical';

export interface DashboardLocation {
  latitude: number;
  longitude: number;
  accuracy: number | null;
  recordedAt: string;
}

export interface DashboardDeviceView {
  id: string;
  label: string;
  status: DeviceStatus;
  manufacturer: string | null;
  model: string | null;
  simOperator: string | null;
  lastSeenAt: string | null;
  enrolledAt: string;
  lastLocation: DashboardLocation | null;
}

export interface DashboardAlert {
  id: string;
  type: 'SIM_CHANGE' | 'REMOTE_COMMAND' | 'DEVICE_STATUS';
  severity: AlertSeverity;
  title: string;
  message: string;
  deviceId: string;
  deviceLabel: string;
  occurredAt: string;
}

export interface DashboardStats {
  devices: {
    total: number;
    active: number;
    lost: number;
    recovered: number;
    disabled: number;
  };
  locations: number;
  photos: number;
  simChanges: number;
  commands: number;
  alertsLast24h: number;
}

export interface DashboardOverview {
  stats: DashboardStats;
  devices: DashboardDeviceView[];
  generatedAt: string;
}

@Injectable()
export class DashboardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
  ) {}

  async getOverview(userId: string): Promise<DashboardOverview> {
    const deviceRows = await this.devices.findAllForUser(userId);
    const devices = await Promise.all(
      deviceRows.map((device) => this.toDeviceView(device)),
    );

    return {
      stats: await this.getStats(userId, deviceRows),
      devices,
      generatedAt: new Date().toISOString(),
    };
  }

  async getStats(userId: string, devices?: Device[]): Promise<DashboardStats> {
    const deviceRows = devices ?? (await this.devices.findAllForUser(userId));
    const deviceIds = deviceRows.map((device) => device.id);
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const [locations, photos, simChanges, commands, alertsLast24h] =
      await Promise.all([
        deviceIds.length
          ? this.prisma.location.count({ where: { deviceId: { in: deviceIds } } })
          : Promise.resolve(0),
        deviceIds.length
          ? this.prisma.photo.count({ where: { deviceId: { in: deviceIds } } })
          : Promise.resolve(0),
        deviceIds.length
          ? this.prisma.simChange.count({
              where: { deviceId: { in: deviceIds } },
            })
          : Promise.resolve(0),
        deviceIds.length
          ? this.prisma.command.count({ where: { deviceId: { in: deviceIds } } })
          : Promise.resolve(0),
        this.countAlertsSince(userId, deviceRows, since),
      ]);

    return {
      devices: {
        total: deviceRows.length,
        active: deviceRows.filter((d) => d.status === DeviceStatus.ACTIVE)
          .length,
        lost: deviceRows.filter((d) => d.status === DeviceStatus.LOST).length,
        recovered: deviceRows.filter((d) => d.status === DeviceStatus.RECOVERED)
          .length,
        disabled: deviceRows.filter((d) => d.status === DeviceStatus.DISABLED)
          .length,
      },
      locations,
      photos,
      simChanges,
      commands,
      alertsLast24h,
    };
  }

  async getAlerts(userId: string, limit = 50): Promise<DashboardAlert[]> {
    const devices = await this.devices.findAllForUser(userId);
    const labels = new Map(devices.map((device) => [device.id, device.label]));
    const deviceIds = devices.map((device) => device.id);
    if (deviceIds.length === 0) return [];

    const take = Math.min(Math.max(limit, 1), 200);

    const [simChanges, commands] = await Promise.all([
      this.prisma.simChange.findMany({
        where: { deviceId: { in: deviceIds } },
        orderBy: { detectedAt: 'desc' },
        take,
      }),
      this.prisma.command.findMany({
        where: { deviceId: { in: deviceIds } },
        orderBy: { issuedAt: 'desc' },
        take,
      }),
    ]);

    const alerts: DashboardAlert[] = [
      ...simChanges.map((change) =>
        this.simChangeToAlert(change, labels.get(change.deviceId) ?? 'Device'),
      ),
      ...commands.map((command) =>
        this.commandToAlert(command, labels.get(command.deviceId) ?? 'Device'),
      ),
      ...devices
        .filter((device) => device.status === DeviceStatus.LOST)
        .map((device) => this.lostDeviceAlert(device)),
    ];

    alerts.sort(
      (a, b) =>
        new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime(),
    );

    return alerts.slice(0, take);
  }

  private async toDeviceView(device: Device): Promise<DashboardDeviceView> {
    const lastLocation = await this.prisma.location.findFirst({
      where: { deviceId: device.id },
      orderBy: { recordedAt: 'desc' },
    });

    return {
      id: device.id,
      label: device.label,
      status: device.status,
      manufacturer: device.manufacturer,
      model: device.model,
      simOperator: device.simOperator,
      lastSeenAt: device.lastSeenAt?.toISOString() ?? null,
      enrolledAt: device.enrolledAt.toISOString(),
      lastLocation: lastLocation ? this.toLocationView(lastLocation) : null,
    };
  }

  private toLocationView(location: Location): DashboardLocation {
    return {
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      recordedAt: location.recordedAt.toISOString(),
    };
  }

  private simChangeToAlert(
    change: SimChange,
    deviceLabel: string,
  ): DashboardAlert {
    return {
      id: `sim-${change.id}`,
      type: 'SIM_CHANGE',
      severity: 'critical',
      title: 'SIM card replaced',
      message: `SIM changed on ${deviceLabel}${
        change.newOperator ? ` · ${change.newOperator}` : ''
      }`,
      deviceId: change.deviceId,
      deviceLabel,
      occurredAt: change.detectedAt.toISOString(),
    };
  }

  private commandToAlert(command: Command, deviceLabel: string): DashboardAlert {
    const title = this.commandTitle(command.type);
    const severity =
      command.type === CommandType.ACTIVATE_THEFT_MODE ? 'critical' : 'info';

    return {
      id: `cmd-${command.id}`,
      type: 'REMOTE_COMMAND',
      severity,
      title,
      message: `${title} on ${deviceLabel} · ${command.status}`,
      deviceId: command.deviceId,
      deviceLabel,
      occurredAt: command.issuedAt.toISOString(),
    };
  }

  private lostDeviceAlert(device: Device): DashboardAlert {
    return {
      id: `lost-${device.id}`,
      type: 'DEVICE_STATUS',
      severity: 'critical',
      title: 'Device in theft mode',
      message: `${device.label} is marked LOST`,
      deviceId: device.id,
      deviceLabel: device.label,
      occurredAt: (device.lastSeenAt ?? device.updatedAt).toISOString(),
    };
  }

  private commandTitle(type: CommandType): string {
    switch (type) {
      case CommandType.ACTIVATE_THEFT_MODE:
        return 'Theft mode activated';
      case CommandType.REQUEST_LIVE_LOCATION:
        return 'Live location requested';
      case CommandType.TRIGGER_ALARM:
        return 'Alarm triggered';
      case CommandType.CAPTURE_IMAGE:
        return 'Evidence capture requested';
      default:
        return 'Remote command issued';
    }
  }

  private async countAlertsSince(
    userId: string,
    devices: Device[],
    since: Date,
  ): Promise<number> {
    const alerts = await this.getAlerts(userId, 200);
    return alerts.filter(
      (alert) => new Date(alert.occurredAt).getTime() >= since.getTime(),
    ).length;
  }
}

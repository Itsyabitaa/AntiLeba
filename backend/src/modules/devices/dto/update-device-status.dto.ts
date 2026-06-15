import { DeviceStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class UpdateDeviceStatusDto {
  @IsEnum(DeviceStatus)
  status!: DeviceStatus;
}

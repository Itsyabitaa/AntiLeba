import { CommandType } from '@prisma/client';
import {
  IsEnum,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class IssueCommandDto {
  @IsUUID()
  deviceId!: string;

  @IsEnum(CommandType)
  type!: CommandType;

  @IsOptional()
  @IsString()
  @MaxLength(36)
  clientEventId?: string;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}

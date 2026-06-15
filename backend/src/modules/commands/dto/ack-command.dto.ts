import { CommandStatus } from '@prisma/client';
import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class AckCommandDto {
  @IsUUID()
  commandId!: string;

  @IsUUID()
  deviceId!: string;

  @IsEnum(CommandStatus)
  status!: CommandStatus;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  errorMessage?: string;
}

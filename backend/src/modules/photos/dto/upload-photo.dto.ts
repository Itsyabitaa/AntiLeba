import {
  IsDateString,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export enum PhotoTriggerDto {
  SIM_REPLACEMENT = 'SIM_REPLACEMENT',
  REMOTE_COMMAND = 'REMOTE_COMMAND',
  UNLOCK_FAILURE = 'UNLOCK_FAILURE',
  MANUAL = 'MANUAL',
}

export class UploadPhotoDto {
  @IsUUID()
  deviceId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(36)
  clientEventId?: string;

  @IsEnum(PhotoTriggerDto)
  trigger!: PhotoTriggerDto;

  @IsDateString()
  capturedAt!: string;
}

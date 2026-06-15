import {
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterDeviceDto {
  @IsString()
  @MinLength(8)
  @MaxLength(190)
  deviceUid!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  label!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  manufacturer?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  model?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  osVersion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  appVersion?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  simSerial?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  simOperator?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  pushToken?: string;
}

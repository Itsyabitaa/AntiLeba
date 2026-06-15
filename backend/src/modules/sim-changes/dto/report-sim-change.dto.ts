import {
  IsDateString,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class ReportSimChangeDto {
  @IsUUID()
  deviceId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(36)
  clientEventId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  previousSerial?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  newSerial?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  previousOperator?: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  newOperator?: string;

  @IsDateString()
  detectedAt!: string;
}

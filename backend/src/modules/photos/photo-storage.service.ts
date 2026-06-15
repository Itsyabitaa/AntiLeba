import { Injectable } from '@nestjs/common';
import { mkdir, writeFile } from 'fs/promises';
import { join } from 'path';

@Injectable()
export class PhotoStorageService {
  private readonly rootDir = join(process.cwd(), 'uploads', 'photos');

  async save(
    userId: string,
    deviceId: string,
    filename: string,
    buffer: Buffer,
  ): Promise<string> {
    const dir = join(this.rootDir, userId, deviceId);
    await mkdir(dir, { recursive: true });
    const absolutePath = join(dir, filename);
    await writeFile(absolutePath, buffer);
    return join('photos', userId, deviceId, filename).replace(/\\/g, '/');
  }
}

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('Health (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();
  });

  it('GET /api/health → 200 + status: ok|degraded', () => {
    return request(app.getHttpServer())
      .get('/api/health')
      .expect(200)
      .expect((res: { body: { status: string } }) => {
        if (!['ok', 'degraded'].includes(res.body.status)) {
          throw new Error(`expected ok|degraded, got ${res.body.status}`);
        }
      });
  });

  afterEach(async () => {
    await app.close();
  });
});

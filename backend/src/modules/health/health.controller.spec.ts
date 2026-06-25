import { HealthController } from './health.controller';

function mockRes() {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('HealthController', () => {
  let prisma: any;
  let config: any;
  let controller: HealthController;

  beforeEach(() => {
    prisma = { $queryRaw: jest.fn().mockResolvedValue([{ ok: 1 }]) };
    config = { get: jest.fn().mockReturnValue(undefined) }; // no REDIS_URL
    controller = new HealthController(prisma, config);
  });

  afterEach(async () => {
    await controller.onModuleDestroy();
  });

  it('live always returns 200 without touching dependencies', () => {
    const res = mockRes();
    controller.live(res);
    expect(res.status).toHaveBeenCalledWith(200);
    expect(prisma.$queryRaw).not.toHaveBeenCalled();
  });

  it('ready returns 200 when DB is ok and Redis is not configured', async () => {
    const res = mockRes();
    await controller.ready(res);
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'ok',
        database: 'ok',
        redis: 'not_configured',
      }),
    );
  });

  it('ready returns 503 when the database is unreachable', async () => {
    prisma.$queryRaw.mockRejectedValue(new Error('down'));
    const res = mockRes();
    await controller.ready(res);
    expect(res.status).toHaveBeenCalledWith(503);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ status: 'degraded', database: 'unreachable' }),
    );
  });

  it('legacy /health returns 503 when the database is unreachable', async () => {
    prisma.$queryRaw.mockRejectedValue(new Error('down'));
    const res = mockRes();
    await controller.check(res);
    expect(res.status).toHaveBeenCalledWith(503);
  });
});

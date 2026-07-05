import { UnauthorizedException } from '@nestjs/common';
import { UserStatus } from '@prisma/client';
import { AuthService } from './auth.service';

/**
 * AUTH PROOF (Flow #4): the two security invariants that protect every session.
 *  1. Refresh-token ROTATION: a used refresh token is revoked and a fresh pair is
 *     issued, so a stolen/replayed refresh token cannot be used twice.
 *  2. OTP is SINGLE-USE and expiry-guarded: a valid code is consumed (usedAt set)
 *     and an invalid/expired/used code is rejected.
 */
function makeDeps(overrides: { user?: any; storedToken?: any; otp?: any } = {}) {
  const prisma: any = {
    refreshToken: {
      findFirst: jest.fn().mockResolvedValue(
        overrides.storedToken === undefined
          ? { id: 'rt-1', userId: 'user-1' }
          : overrides.storedToken,
      ),
      update: jest.fn().mockResolvedValue({}),
      create: jest.fn().mockResolvedValue({}),
    },
    user: {
      findUnique: jest.fn().mockResolvedValue(
        overrides.user === undefined
          ? { id: 'user-1', role: 'CUSTOMER', status: UserStatus.ACTIVE, restaurantId: null, branchId: null, riderProfile: null }
          : overrides.user,
      ),
    },
    otpCode: {
      findFirst: jest.fn().mockResolvedValue(
        overrides.otp === undefined ? { id: 'otp-1' } : overrides.otp,
      ),
      update: jest.fn().mockResolvedValue({}),
    },
  };
  const jwt: any = {
    verifyAsync: jest.fn().mockResolvedValue({ sub: 'user-1' }),
    signAsync: jest.fn().mockResolvedValue('new-token'),
  };
  const config: any = {
    getOrThrow: jest.fn().mockReturnValue('a-secret'),
    get: jest.fn().mockReturnValue(undefined), // fall back to code defaults
  };
  const sms: any = { sendOtp: jest.fn() };
  return { service: new AuthService(prisma, jwt, config, sms), prisma, jwt };
}

describe('AuthService.refresh — token rotation', () => {
  it('revokes the presented refresh token and issues a fresh pair', async () => {
    const { service, prisma } = makeDeps();

    const result = await service.refresh('valid.refresh.jwt');

    // The old token is revoked (single-use rotation)...
    expect(prisma.refreshToken.update).toHaveBeenCalledWith({
      where: { id: 'rt-1' },
      data: { revokedAt: expect.any(Date) },
    });
    // ...and a new refresh token is persisted.
    expect(prisma.refreshToken.create).toHaveBeenCalledTimes(1);
    expect(result).toHaveProperty('accessToken');
    expect(result).toHaveProperty('refreshToken');
  });

  it('rejects a refresh token with a bad signature', async () => {
    const { service, jwt } = makeDeps();
    jwt.verifyAsync.mockRejectedValueOnce(new Error('bad sig'));

    await expect(service.refresh('tampered')).rejects.toThrow('Invalid refresh token');
  });

  it('rejects a refresh token that is not in the store (already rotated / revoked)', async () => {
    const { service } = makeDeps({ storedToken: null });

    await expect(service.refresh('replayed')).rejects.toThrow('Refresh token revoked');
  });

  it('rejects refresh when the user is no longer active', async () => {
    const { service } = makeDeps({
      user: { id: 'user-1', role: 'CUSTOMER', status: UserStatus.SUSPENDED, riderProfile: null },
    });

    await expect(service.refresh('valid')).rejects.toThrow('User inactive');
  });
});

describe('AuthService.validateOtp — single-use & expiry', () => {
  const dto = { purpose: 'LOGIN', code: '123456', phone: '01700000000' } as any;

  it('consumes a valid OTP exactly once (marks it used)', async () => {
    const { service, prisma } = makeDeps();

    const record = await (service as any).validateOtp(dto);

    expect(record).toEqual({ id: 'otp-1' });
    expect(prisma.otpCode.update).toHaveBeenCalledWith({
      where: { id: 'otp-1' },
      data: { usedAt: expect.any(Date) },
    });
  });

  it('rejects an invalid / expired / already-used OTP', async () => {
    const { service, prisma } = makeDeps({ otp: null });

    await expect((service as any).validateOtp(dto)).rejects.toThrow(UnauthorizedException);
    expect(prisma.otpCode.update).not.toHaveBeenCalled();
  });
});

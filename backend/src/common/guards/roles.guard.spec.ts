import { UnauthorizedException } from '@nestjs/common';
import { RolesGuard } from './roles.guard';
import { UserRole } from '../enums/user-role.enum';

/**
 * ACCESS-CONTROL PROOF (Flow #4): the RolesGuard is the wall between roles. A
 * CUSTOMER token must never satisfy an ADMIN-only route, an unauthenticated
 * request must be rejected, and unrestricted routes must stay open. These are
 * the cross-role blocks that stop a customer from hitting staff/admin endpoints.
 */
function makeContext(user: unknown, requiredRoles: UserRole[] | undefined) {
  const reflector = {
    getAllAndOverride: jest.fn().mockReturnValue(requiredRoles),
  } as any;
  const context = {
    getHandler: () => null,
    getClass: () => null,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as any;
  return { guard: new RolesGuard(reflector), context };
}

describe('RolesGuard', () => {
  it('allows a route with no role restriction', () => {
    const { guard, context } = makeContext({ role: UserRole.CUSTOMER }, undefined);
    expect(guard.canActivate(context)).toBe(true);
  });

  it('allows a user whose role is in the required set', () => {
    const { guard, context } = makeContext({ role: UserRole.ADMIN }, [UserRole.ADMIN]);
    expect(guard.canActivate(context)).toBe(true);
  });

  it('BLOCKS a customer from an admin-only route', () => {
    const { guard, context } = makeContext({ role: UserRole.CUSTOMER }, [UserRole.ADMIN]);
    expect(guard.canActivate(context)).toBe(false);
  });

  it('BLOCKS a rider from a staff/kitchen route', () => {
    const { guard, context } = makeContext({ role: UserRole.RIDER }, [
      UserRole.OWNER,
      UserRole.MANAGER,
      UserRole.KITCHEN,
    ]);
    expect(guard.canActivate(context)).toBe(false);
  });

  it('rejects an unauthenticated request on a protected route', () => {
    const { guard, context } = makeContext(undefined, [UserRole.ADMIN]);
    expect(() => guard.canActivate(context)).toThrow(UnauthorizedException);
  });
});

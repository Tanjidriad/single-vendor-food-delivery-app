import { ForbiddenException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { JwtPayload } from '../../modules/auth/interfaces/jwt-payload.interface';

const STAFF: UserRole[] = [
  UserRole.OWNER,
  UserRole.MANAGER,
  UserRole.CASHIER,
  UserRole.KITCHEN,
  UserRole.ADMIN,
];

export function requireRestaurantId(user: JwtPayload): string {
  if (!STAFF.includes(user.role) || !user.restaurantId) {
    throw new ForbiddenException('Restaurant staff access required');
  }
  return user.restaurantId;
}

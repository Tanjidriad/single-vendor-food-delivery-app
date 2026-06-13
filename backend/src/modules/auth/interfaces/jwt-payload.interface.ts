import { UserRole } from '../../../common/enums/user-role.enum';

export class JwtPayload {
  sub: string;
  role: UserRole;
  restaurantId?: string | null;
  branchId?: string | null;
  riderProfileId?: string | null;
}

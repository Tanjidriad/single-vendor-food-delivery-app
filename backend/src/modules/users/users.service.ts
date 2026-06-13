import { ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { RiderApprovalStatus, UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { DispatchService } from '../dispatch/dispatch.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private prisma: PrismaService,
    private dispatch: DispatchService,
  ) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        customerProfile: true,
        staffProfile: true,
        riderProfile: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    const { passwordHash: _, ...safe } = user;
    return safe;
  }

  async updateProfile(userId: string, role: UserRole, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        customerProfile: true,
        staffProfile: true,
        riderProfile: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');

    if (dto.phone) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { phone: dto.phone },
      });
    }

    if (role === UserRole.CUSTOMER && user.customerProfile) {
      const customerData: { fullName?: string; avatarUrl?: string } = {};
      if (dto.fullName) customerData.fullName = dto.fullName;
      if (dto.avatarUrl) customerData.avatarUrl = dto.avatarUrl;
      if (Object.keys(customerData).length > 0) {
        await this.prisma.customerProfile.update({
          where: { userId },
          data: customerData,
        });
      }
    }

    if (
      user.staffProfile &&
      dto.fullName &&
      (
        [
          UserRole.OWNER,
          UserRole.MANAGER,
          UserRole.CASHIER,
          UserRole.KITCHEN,
        ] as UserRole[]
      ).includes(role)
    ) {
      await this.prisma.staffProfile.update({
        where: { userId },
        data: { fullName: dto.fullName },
      });
    }

    if (user.riderProfile && dto.fullName && role === UserRole.RIDER) {
      await this.prisma.riderProfile.update({
        where: { userId },
        data: { fullName: dto.fullName },
      });
    }

    return this.getProfile(userId);
  }

  async setRiderOnline(userId: string, isOnline: boolean) {
    const profile = await this.prisma.riderProfile.findUnique({
      where: { userId },
    });
    if (!profile) throw new NotFoundException('Rider profile not found');
    // Only an APPROVED rider may go online. A PENDING rider can hold a token
    // (to finish onboarding) but must not be able to receive real assignments.
    if (isOnline && profile.approvalStatus !== RiderApprovalStatus.APPROVED) {
      throw new ForbiddenException(
        'Your rider account must be approved before going online',
      );
    }
    const updated = await this.prisma.riderProfile.update({
      where: { userId },
      data: { isOnline },
    });

    if (isOnline) {
      void this.dispatch
        .retryDispatchWhenRiderGoesOnline(updated.id)
        .catch((err) => {
          this.logger.warn(
            `Rider-online dispatch retry failed for ${updated.id}: ${
              err instanceof Error ? err.message : err
            }`,
          );
        });
    }

    return updated;
  }
}

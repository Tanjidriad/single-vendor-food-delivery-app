import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Injectable()
export class DevicesService {
  constructor(private prisma: PrismaService) {}

  async register(userId: string, dto: RegisterDeviceDto) {
    return this.prisma.deviceToken.upsert({
      where: { userId_deviceId: { userId, deviceId: dto.deviceId } },
      update: {
        token: dto.token,
        platform: dto.platform,
        isActive: true,
        lastSeenAt: new Date(),
      },
      create: {
        userId,
        deviceId: dto.deviceId,
        platform: dto.platform,
        token: dto.token,
      },
    });
  }

  async refreshToken(userId: string, dto: RegisterDeviceDto) {
    return this.register(userId, dto);
  }

  async deactivate(userId: string, deviceId: string) {
    return this.prisma.deviceToken.updateMany({
      where: { userId, deviceId },
      data: { isActive: false },
    });
  }

  async getActiveTokens(userId: string) {
    return this.prisma.deviceToken.findMany({
      where: { userId, isActive: true },
    });
  }
}

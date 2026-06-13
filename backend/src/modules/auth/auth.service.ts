import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UserRole, UserStatus } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { createHash, randomBytes, randomInt } from 'crypto';
import { Resend } from 'resend';
import { PrismaService } from '../../prisma/prisma.service';
import { SmsService } from '../notifications/sms.service';
import { LoginDto } from './dto/login.dto';
import { ResetPasswordDto, SendOtpDto, VerifyOtpDto } from './dto/otp.dto';
import { RegisterDto } from './dto/register.dto';
import { RegisterRiderDto } from './dto/register-rider.dto';
import { JwtPayload } from './interfaces/jwt-payload.interface';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
    private sms: SmsService,
  ) {}

  async register(dto: RegisterDto) {
    if (!dto.email && !dto.phone) {
      throw new ConflictException('Email or phone is required');
    }
    if (dto.email) {
      const exists = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });
      if (exists) throw new ConflictException('Email already registered');
    }
    if (dto.phone) {
      const exists = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
      });
      if (exists) throw new ConflictException('Phone already registered');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        phone: dto.phone,
        passwordHash,
        role: UserRole.CUSTOMER,
        status: UserStatus.ACTIVE,
        customerProfile: { create: { fullName: dto.fullName } },
      },
      include: { customerProfile: true },
    });

    return this.issueTokens(user.id, user.role, user.restaurantId, user.branchId);
  }

  async registerRider(dto: RegisterRiderDto) {
    const existsPhone = await this.prisma.user.findFirst({
      where: { phone: dto.phone },
    });
    if (existsPhone) throw new ConflictException('Phone already registered');

    const existsEmail = await this.prisma.user.findFirst({
      where: { email: dto.email },
    });
    if (existsEmail) throw new ConflictException('Email already registered');

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        phone: dto.phone,
        passwordHash,
        role: UserRole.RIDER,
        status: UserStatus.ACTIVE,
        riderProfile: {
          create: {
            fullName: dto.fullName,
            vehicleType: dto.vehicleType,
            // approvalStatus defaults to PENDING based on schema
          },
        },
      },
      include: { riderProfile: true },
    });

    // Issue a session so the onboarding flow can immediately upload documents
    // and set work details. The rider is still PENDING: operational endpoints
    // (go-online, accept-assignment) are gated on APPROVED, so this token only
    // unlocks self-service profile/document setup, not real delivery work.
    const tokens = await this.issueTokens(
      user.id,
      user.role,
      user.restaurantId,
      user.branchId,
      user.riderProfile?.id,
    );
    return {
      ...tokens,
      approvalStatus: user.riderProfile?.approvalStatus,
      message:
        'Registration submitted. Complete your profile, then wait for admin approval.',
    };
  }

  async login(dto: LoginDto) {
    if (!dto.email && !dto.phone) {
      throw new UnauthorizedException('Email or phone required');
    }
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          dto.email ? { email: dto.email } : undefined,
          dto.phone ? { phone: dto.phone } : undefined,
        ].filter(Boolean) as { email?: string; phone?: string }[],
      },
      include: { riderProfile: true },
    });
    if (!user?.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Account is not active');
    }

    if (user.role === UserRole.RIDER && user.riderProfile) {
      if (user.riderProfile.approvalStatus === 'PENDING') {
        throw new UnauthorizedException('Your rider account is pending admin approval');
      } else if (user.riderProfile.approvalStatus === 'REJECTED') {
        throw new UnauthorizedException('Your rider application was rejected');
      } else if (user.riderProfile.approvalStatus === 'SUSPENDED') {
        throw new UnauthorizedException('Your rider account is suspended');
      }
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    return this.issueTokens(
      user.id,
      user.role,
      user.restaurantId,
      user.branchId,
      user.riderProfile?.id,
    );
  }

  async refresh(refreshToken: string) {
    let payload: { sub: string };
    try {
      payload = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.getOrThrow<string>('jwt.refreshSecret'),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const hash = this.hashToken(refreshToken);
    const stored = await this.prisma.refreshToken.findFirst({
      where: {
        userId: payload.sub,
        tokenHash: hash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (!stored) throw new UnauthorizedException('Refresh token revoked');

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { riderProfile: true },
    });
    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('User inactive');
    }

    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });

    return this.issueTokens(
      user.id,
      user.role,
      user.restaurantId,
      user.branchId,
      user.riderProfile?.id,
    );
  }

  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      const hash = this.hashToken(refreshToken);
      await this.prisma.refreshToken.updateMany({
        where: { userId, tokenHash: hash, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    } else {
      await this.prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    return { success: true };
  }

  private async issueTokens(
    userId: string,
    role: UserRole,
    restaurantId?: string | null,
    branchId?: string | null,
    riderProfileId?: string | null,
  ) {
    const payload: JwtPayload = {
      sub: userId,
      role,
      restaurantId,
      branchId,
      riderProfileId,
    };

    const accessExpires =
      (this.config.get<string>('jwt.accessExpiresIn') ?? '15m') as `${number}m`;
    const refreshExpires =
      (this.config.get<string>('jwt.refreshExpiresIn') ?? '7d') as `${number}d`;

    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.getOrThrow<string>('jwt.accessSecret'),
      expiresIn: accessExpires,
    });

    const refreshToken = await this.jwt.signAsync(
      { sub: userId },
      {
        secret: this.config.getOrThrow<string>('jwt.refreshSecret'),
        expiresIn: refreshExpires,
      },
    );

    const expiresAt = new Date();
    const refreshExpiry = this.config.get<string>('jwt.refreshExpiresIn') ?? '7d';
    const match = refreshExpiry.match(/^(\d+)([smhd])$/);
    if (match) {
      const value = parseInt(match[1], 10);
      const unit = match[2];
      switch (unit) {
        case 's': expiresAt.setSeconds(expiresAt.getSeconds() + value); break;
        case 'm': expiresAt.setMinutes(expiresAt.getMinutes() + value); break;
        case 'h': expiresAt.setHours(expiresAt.getHours() + value); break;
        case 'd': expiresAt.setDate(expiresAt.getDate() + value); break;
      }
    } else {
      expiresAt.setDate(expiresAt.getDate() + 7); // fallback
    }

    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: this.hashToken(refreshToken),
        expiresAt,
      },
    });

    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: this.config.get<string>('jwt.accessExpiresIn') ?? '15m',
      user: payload,
    };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  async sendOtp(dto: SendOtpDto) {
    if (!dto.phone && !dto.email) {
      throw new BadRequestException('Phone or email required');
    }
    const code = String(randomInt(100000, 1000000));
    const codeHash = this.hashToken(code);
    const expiresAt = new Date();
    expiresAt.setMinutes(
      expiresAt.getMinutes() + this.config.get<number>('otpExpiryMinutes', 10),
    );

    let userId: string | undefined;
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          dto.phone ? { phone: dto.phone } : undefined,
          dto.email ? { email: dto.email } : undefined,
        ].filter(Boolean) as { phone?: string; email?: string }[],
      },
    });
    if ((dto.purpose === 'LOGIN' || dto.purpose === 'RESET_PASSWORD') && !user) {
      throw new NotFoundException('User not found');
    }
    userId = user?.id;

    await this.prisma.otpCode.create({
      data: {
        userId,
        phone: dto.phone,
        email: dto.email,
        codeHash,
        purpose: dto.purpose,
        expiresAt,
      },
    });

    const otpExpiryMinutes = this.config.get<number>('otpExpiryMinutes', 10);
    const nodeEnv = this.config.get<string>('nodeEnv') ?? 'production';
    const isProd = nodeEnv === 'production';

    let phoneDelivered = false;
    if (dto.phone) {
      if (this.sms.isEnabled()) {
        phoneDelivered = await this.sms.sendOtp(
          dto.phone,
          code,
          otpExpiryMinutes,
        );
      }
      if (isProd && !phoneDelivered) {
        throw new ServiceUnavailableException(
          'SMS OTP delivery failed. Check Twilio configuration.',
        );
      }
    }

    const resendApiKey = this.config.get<string>('resendApiKey');
    if (dto.email && resendApiKey) {
      try {
        const resend = new Resend(resendApiKey);
        const { data, error } = await resend.emails.send({
          from: 'FoodDelivery <noreply@emdadurrahmanbabul.me>',
          to: dto.email,
          subject: 'Your Verification Code',
          html: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>Verification Code</title>
            </head>
            <body style="margin: 0; padding: 0; background-color: #f9fafb; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #111827;">
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f9fafb; padding: 40px 20px;">
                <tr>
                  <td align="center">
                    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 600px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05), 0 10px 15px rgba(0, 0, 0, 0.02);">
                      <!-- Header -->
                      <tr>
                        <td style="background: linear-gradient(135deg, #FF4B2B 0%, #FF416C 100%); padding: 32px 40px; text-align: center;">
                          <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px;">FoodDelivery</h1>
                        </td>
                      </tr>
                      <!-- Body -->
                      <tr>
                        <td style="padding: 48px 40px;">
                          <h2 style="margin: 0 0 16px 0; font-size: 24px; font-weight: 700; color: #111827;">Verify your email</h2>
                          <p style="margin: 0 0 32px 0; font-size: 16px; line-height: 24px; color: #4b5563;">
                            Almost there! Please enter the 6-digit code below to securely verify your account.
                          </p>
                          
                          <!-- OTP Box -->
                          <div style="background-color: #f3f4f6; border-radius: 12px; padding: 24px; text-align: center; border: 1px solid #e5e7eb;">
                            <span style="font-family: monospace; font-size: 40px; font-weight: 700; letter-spacing: 12px; color: #111827; margin-left: 12px;">${code}</span>
                          </div>
                          
                          <p style="margin: 32px 0 0 0; font-size: 14px; color: #6b7280; text-align: center;">
                            This code is valid for <strong>${this.config.get<number>('otpExpiryMinutes', 10)} minutes</strong>.<br>
                            If you didn't request this, you can safely ignore it.
                          </p>
                        </td>
                      </tr>
                      <!-- Footer -->
                      <tr>
                        <td style="background-color: #f9fafb; padding: 24px 40px; text-align: center; border-top: 1px solid #f3f4f6;">
                          <p style="margin: 0; font-size: 12px; color: #9ca3af;">
                            &copy; ${new Date().getFullYear()} FoodDelivery Inc. All rights reserved.
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </body>
            </html>
          `
        });
        if (error) {
          this.logger.error(`[Resend] API Error:`, error);
        } else {
          this.logger.log(`[Resend] Successfully sent OTP to ${dto.email}, id: ${data?.id}`);
        }
      } catch (err) {
        this.logger.error(`[Resend] Failed to send email to ${dto.email}`, err);
      }
    }

    if (nodeEnv === 'development') {
      this.logger.log(
        `[OTP ${dto.purpose}] ${dto.phone ?? dto.email} => ${code} (expires ${expiresAt.toISOString()})`,
      );
    } else {
      this.logger.log(
        `[OTP ${dto.purpose}] ${dto.phone ?? dto.email} (expires ${expiresAt.toISOString()})`,
      );
    }

    return {
      success: true,
      message: 'OTP sent',
      expiresAt,
      devCode:
        nodeEnv === 'development' && !resendApiKey && !phoneDelivered
          ? code
          : undefined,
    };
  }

  async verifyOtpLogin(dto: VerifyOtpDto) {
    await this.validateOtp(dto);
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          dto.phone ? { phone: dto.phone } : undefined,
          dto.email ? { email: dto.email } : undefined,
        ].filter(Boolean) as { phone?: string; email?: string }[],
      },
      include: { riderProfile: true },
    });
    if (!user) throw new NotFoundException('User not found');
    return this.issueTokens(
      user.id,
      user.role,
      user.restaurantId,
      user.branchId,
      user.riderProfile?.id,
    );
  }

  async resetPassword(dto: ResetPasswordDto) {
    await this.validateOtp({
      phone: dto.phone,
      email: dto.email,
      purpose: 'RESET_PASSWORD',
      code: dto.code,
    });
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          dto.phone ? { phone: dto.phone } : undefined,
          dto.email ? { email: dto.email } : undefined,
        ].filter(Boolean) as { phone?: string; email?: string }[],
      },
    });
    if (!user) throw new NotFoundException('User not found');
    const passwordHash = await bcrypt.hash(dto.newPassword, 12);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });
    return { success: true, message: 'Password updated' };
  }

  private async validateOtp(dto: VerifyOtpDto) {
    const codeHash = this.hashToken(dto.code);
    const record = await this.prisma.otpCode.findFirst({
      where: {
        purpose: dto.purpose,
        codeHash,
        usedAt: null,
        expiresAt: { gt: new Date() },
        OR: [
          dto.phone ? { phone: dto.phone } : undefined,
          dto.email ? { email: dto.email } : undefined,
        ].filter(Boolean) as { phone?: string; email?: string }[],
      },
      orderBy: { createdAt: 'desc' },
    });
    if (!record) throw new UnauthorizedException('Invalid or expired OTP');
    await this.prisma.otpCode.update({
      where: { id: record.id },
      data: { usedAt: new Date() },
    });
    return record;
  }
}

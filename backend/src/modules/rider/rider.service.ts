import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RiderDocumentType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { UpdateRiderProfileDto } from './dto/update-rider-profile.dto';
import 'multer';

/// Rider self-service: work-details profile edits and verification-document
/// uploads. Every method is scoped to the caller's own rider profile (taken
/// from the JWT), so one rider can never read or mutate another's data.
@Injectable()
export class RiderService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: UploadsService,
  ) {}

  /// Resolves the caller's rider profile id from the JWT, rejecting non-riders
  /// or tokens minted before a rider profile existed.
  private requireRiderProfileId(user: JwtPayload): string {
    if (!user.riderProfileId) {
      throw new BadRequestException('No rider profile for this account');
    }
    return user.riderProfileId;
  }

  async getProfile(user: JwtPayload) {
    const id = this.requireRiderProfileId(user);
    const profile = await this.prisma.riderProfile.findUnique({
      where: { id },
      include: {
        user: { select: { phone: true, email: true } },
        documents: { orderBy: { uploadedAt: 'desc' } },
      },
    });
    if (!profile) throw new NotFoundException('Rider profile not found');
    return profile;
  }

  async updateProfile(user: JwtPayload, dto: UpdateRiderProfileDto) {
    const id = this.requireRiderProfileId(user);
    return this.prisma.riderProfile.update({
      where: { id },
      data: {
        vehicleType: dto.vehicleType,
        vehicleModel: dto.vehicleModel,
        vehicleRegistration: dto.vehicleRegistration,
        zone: dto.zone,
      },
    });
  }

  async listDocuments(user: JwtPayload) {
    const id = this.requireRiderProfileId(user);
    return this.prisma.riderDocument.findMany({
      where: { riderId: id },
      orderBy: { uploadedAt: 'desc' },
    });
  }

  async uploadDocument(
    user: JwtPayload,
    file: Express.Multer.File,
    type: RiderDocumentType,
  ) {
    const id = this.requireRiderProfileId(user);
    if (!file) throw new BadRequestException('A document file is required');

    // Reuse the shared Cloudinary uploader (validates type/size). Documents
    // live under a per-rider folder, away from restaurant media.
    const { url, publicId } = await this.uploads.uploadImage(
      file,
      `rider_${id}/docs`,
    );

    return this.prisma.riderDocument.create({
      data: { riderId: id, type, url, publicId },
    });
  }
}

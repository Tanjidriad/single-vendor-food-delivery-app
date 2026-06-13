import { Injectable, NotFoundException } from '@nestjs/common';
import { MediaCategory } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';
import 'multer';

@Injectable()
export class MediaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploadsService: UploadsService,
  ) {}

  async findAll(restaurantId: string, category?: MediaCategory) {
    return this.prisma.media.findMany({
      where: {
        restaurantId,
        ...(category ? { category } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async uploadAndSave(
    restaurantId: string,
    file: Express.Multer.File,
    category: MediaCategory,
  ) {
    // 1. Upload to Cloudinary using existing UploadsService
    const folder = `restaurant_${restaurantId}/${category.toLowerCase()}`;
    const { url, publicId } = await this.uploadsService.uploadImage(file, folder);

    // 2. Save record in database
    return this.prisma.media.create({
      data: {
        restaurantId,
        url,
        publicId,
        filename: file.originalname,
        category,
        sizeBytes: file.size,
        mimeType: file.mimetype,
      },
    });
  }

  async deleteMedia(restaurantId: string, mediaId: string) {
    const media = await this.prisma.media.findUnique({
      where: { id: mediaId },
    });

    if (!media || media.restaurantId !== restaurantId) {
      throw new NotFoundException('Media not found');
    }

    // 1. Delete from Cloudinary
    if (media.publicId) {
      await this.uploadsService.deleteImage(media.publicId);
    }

    // 2. Delete from database
    await this.prisma.media.delete({ where: { id: mediaId } });
    return { success: true };
  }
}

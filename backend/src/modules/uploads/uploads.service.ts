import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { Readable } from 'stream';

@Injectable()
export class UploadsService {
  private readonly logger = new Logger(UploadsService.name);
  private configured = false;

  constructor(private config: ConfigService) {
    const cloudName = config.get<string>('cloudinary.cloudName');
    const apiKey = config.get<string>('cloudinary.apiKey');
    const apiSecret = config.get<string>('cloudinary.apiSecret');
    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({ cloud_name: cloudName, api_key: apiKey, api_secret: apiSecret });
      this.configured = true;
    } else {
      this.logger.warn('Cloudinary not configured — uploads will fail');
    }
  }

  async uploadImage(
    file: Express.Multer.File,
    folder = 'food-delivery',
  ): Promise<{ url: string; publicId: string }> {
    if (!this.configured) {
      throw new BadRequestException('Cloudinary is not configured');
    }
    if (!file?.buffer) {
      throw new BadRequestException('File is required');
    }
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
    if (!allowed.includes(file.mimetype)) {
      throw new BadRequestException('Only JPEG, PNG, and WebP images are allowed');
    }
    if (file.size > 5 * 1024 * 1024) {
      throw new BadRequestException('Max file size is 5MB');
    }

    return new Promise((resolve, reject) => {
      const upload = cloudinary.uploader.upload_stream(
        { folder, resource_type: 'image' },
        (error: Error | undefined, result?: { secure_url: string; public_id: string }) => {
          if (error || !result) {
            reject(error ?? new Error('Upload failed'));
            return;
          }
          resolve({ url: result.secure_url, publicId: result.public_id });
        },
      );
      Readable.from(file.buffer).pipe(upload);
    });
  }

  async deleteImage(publicId: string) {
    if (!this.configured) return;
    await cloudinary.uploader.destroy(publicId);
  }
}

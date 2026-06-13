import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { RiderDocumentType, UserRole } from '@prisma/client';
import { memoryStorage } from 'multer';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { UpdateRiderProfileDto } from './dto/update-rider-profile.dto';
import { UploadRiderDocumentDto } from './dto/upload-rider-document.dto';
import { RiderService } from './rider.service';

/// Rider self-service endpoints. All routes are RIDER-only and operate on the
/// caller's own profile (the service derives the rider id from the JWT).
@ApiTags('rider')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.RIDER)
@Controller('rider')
export class RiderController {
  constructor(private readonly riderService: RiderService) {}

  @Get('profile')
  getProfile(@CurrentUser() user: JwtPayload) {
    return this.riderService.getProfile(user);
  }

  @Patch('profile')
  updateProfile(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateRiderProfileDto,
  ) {
    return this.riderService.updateProfile(user, dto);
  }

  @Get('documents')
  listDocuments(@CurrentUser() user: JwtPayload) {
    return this.riderService.listDocuments(user);
  }

  @Post('documents')
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        type: {
          type: 'string',
          enum: Object.values(RiderDocumentType),
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 }, // 5MB, matches UploadsService
    }),
  )
  uploadDocument(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadRiderDocumentDto,
  ) {
    return this.riderService.uploadDocument(user, file, dto.type);
  }
}

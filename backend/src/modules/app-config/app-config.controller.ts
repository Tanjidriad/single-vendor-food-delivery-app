import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('app')
@Controller('app')
export class AppConfigController {
  constructor(private readonly config: ConfigService) {}

  /**
   * Public bootstrap config for client apps. The customer app reads this on
   * launch to enforce a minimum supported version (force-update) and to surface
   * the store update link.
   */
  @Public()
  @Get('config')
  getConfig() {
    const v = this.config.get<{
      minSupportedVersion: string;
      latestVersion: string;
      androidUpdateUrl: string;
      iosUpdateUrl: string;
    }>('appVersioning');

    return {
      minSupportedVersion: v?.minSupportedVersion ?? '1.0.0',
      latestVersion: v?.latestVersion ?? '1.0.0',
      android: { updateUrl: v?.androidUpdateUrl ?? '' },
      ios: { updateUrl: v?.iosUpdateUrl ?? '' },
    };
  }
}

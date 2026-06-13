import { Controller, Get, NotFoundException } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { Public } from '../../common/decorators/public.decorator';
import { DevService } from './dev.service';

@ApiTags('dev')
@Controller('dev')
export class DevController {
  constructor(
    private readonly devService: DevService,
    private readonly config: ConfigService,
  ) {}

  /**
   * Public dev-only endpoint for Flutter/desktop to discover the LAN API URL
   * (physical phone on the same Wi‑Fi as this machine).
   */
  @Public()
  @Get('client-config')
  clientConfig() {
    if (this.config.get<string>('nodeEnv') === 'production') {
      throw new NotFoundException();
    }
    return this.devService.getClientConfig();
  }
}

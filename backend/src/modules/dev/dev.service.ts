import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { writeFileSync } from 'fs';
import { join } from 'path';
import {
  getLanIPv4Addresses,
  pickPrimaryLanHost,
} from '../../common/utils/network-hosts.util';

@Injectable()
export class DevService {
  constructor(private readonly config: ConfigService) {}

  getClientConfig() {
    const port = this.config.get<number>('port') ?? 3000;
    const apiPrefix = this.config.get<string>('apiPrefix') ?? 'api/v1';
    const lanIps = getLanIPv4Addresses();
    const primaryLan = pickPrimaryLanHost(lanIps);

    const apiBaseUrl = primaryLan
      ? `http://${primaryLan}:${port}/${apiPrefix}`
      : `http://localhost:${port}/${apiPrefix}`;

    const socketBaseUrl = primaryLan
      ? `http://${primaryLan}:${port}`
      : `http://localhost:${port}`;

    const hosts = lanIps.map((ip) => `http://${ip}:${port}/${apiPrefix}`);

    return {
      apiBaseUrl,
      socketBaseUrl,
      hosts,
      lanIps,
      emulatorAndroid: {
        apiBaseUrl: `http://10.0.2.2:${port}/${apiPrefix}`,
        socketBaseUrl: `http://10.0.2.2:${port}`,
      },
      localhost: {
        apiBaseUrl: `http://localhost:${port}/${apiPrefix}`,
        socketBaseUrl: `http://localhost:${port}`,
      },
      port,
      apiPrefix,
    };
  }

  /** Writes Flutter asset so physical devices can use the LAN URL after `flutter run`. */
  syncFlutterDevHostAsset(): string | undefined {
    if (this.config.get<string>('nodeEnv') === 'production') return undefined;

    const { apiBaseUrl } = this.getClientConfig();
    const content = [
      '# Auto-generated when the API starts (npm run start:dev).',
      '# Re-run the Flutter app after starting the backend on a physical device.',
      apiBaseUrl,
      '',
    ].join('\n');

    const assetPaths = [
      join(process.cwd(), '../apps/customer_app/assets/dev_api_host.txt'),
      join(process.cwd(), '../apps/kitchen_app/assets/dev_api_host.txt'),
      join(process.cwd(), '../apps/rider_app/assets/dev_api_host.txt'),
    ];

    let written: string | undefined;
    for (const assetPath of assetPaths) {
      try {
        writeFileSync(assetPath, content, 'utf8');
        written ??= assetPath;
      } catch {
        // App folder may not exist in all deployments.
      }
    }
    return written;
  }

  getStartupUrls(port: number, apiPrefix: string) {
    const lanIps = getLanIPv4Addresses();
    const primaryLan = pickPrimaryLanHost(lanIps);

    return {
      local: `http://localhost:${port}/${apiPrefix}`,
      swagger: `http://localhost:${port}/api/docs`,
      androidEmulator: `http://10.0.2.2:${port}/${apiPrefix}`,
      physicalDevice: primaryLan
        ? `http://${primaryLan}:${port}/${apiPrefix}`
        : undefined,
      allLan: lanIps.map((ip) => `http://${ip}:${port}/${apiPrefix}`),
    };
  }
}

import { AppConfigController } from './app-config.controller';

describe('AppConfigController', () => {
  it('returns the configured version gate and store links', () => {
    const config = {
      get: jest.fn().mockReturnValue({
        minSupportedVersion: '1.2.0',
        latestVersion: '1.5.0',
        androidUpdateUrl: 'https://play.google.com/store/apps/details?id=x',
        iosUpdateUrl: '',
      }),
    } as any;

    const result = new AppConfigController(config).getConfig();

    expect(result.minSupportedVersion).toBe('1.2.0');
    expect(result.latestVersion).toBe('1.5.0');
    expect(result.android.updateUrl).toContain('play.google.com');
    expect(result.ios.updateUrl).toBe('');
  });

  it('falls back to safe defaults when unconfigured', () => {
    const config = { get: jest.fn().mockReturnValue(undefined) } as any;

    const result = new AppConfigController(config).getConfig();

    expect(result.minSupportedVersion).toBe('1.0.0');
    expect(result.android.updateUrl).toBe('');
  });
});

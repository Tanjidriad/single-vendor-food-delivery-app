import { corsOriginSetting, parseCorsOrigins } from './cors.util';

describe('cors.util', () => {
  it('parseCorsOrigins splits and trims', () => {
    expect(parseCorsOrigins('https://a.com, https://b.com')).toEqual([
      'https://a.com',
      'https://b.com',
    ]);
  });

  it('parseCorsOrigins defaults to wildcard', () => {
    expect(parseCorsOrigins()).toEqual(['*']);
  });

  it('corsOriginSetting returns true for wildcard', () => {
    expect(corsOriginSetting(['*'])).toBe(true);
  });

  it('corsOriginSetting returns list for explicit origins', () => {
    expect(corsOriginSetting(['https://a.com'])).toEqual(['https://a.com']);
  });
});

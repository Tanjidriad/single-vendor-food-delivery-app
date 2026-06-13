import { networkInterfaces } from 'os';

/** Private IPv4 addresses suitable for phones on the same Wi‑Fi (physical device testing). */
export function getLanIPv4Addresses(): string[] {
  const nets = networkInterfaces();
  const ips = new Set<string>();

  for (const name of Object.keys(nets)) {
    for (const net of nets[name] ?? []) {
      if (net.family !== 'IPv4' || net.internal) continue;
      ips.add(net.address);
    }
  }

  return [...ips];
}

export function pickPrimaryLanHost(addresses: string[]): string | undefined {
  const preferred = addresses.find(
    (ip) =>
      ip.startsWith('192.168.') ||
      ip.startsWith('10.') ||
      ip.startsWith('172.'),
  );
  return preferred ?? addresses[0];
}

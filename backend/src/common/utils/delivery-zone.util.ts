/** Haversine distance in km between two coordinates */
export function distanceKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Ray-casting point-in-polygon for [lng, lat] rings (GeoJSON style) */
export function pointInPolygon(
  lat: number,
  lng: number,
  ring: number[][],
): boolean {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const xi = ring[i][0];
    const yi = ring[i][1];
    const xj = ring[j][0];
    const yj = ring[j][1];
    const intersect =
      yi > lat !== yj > lat &&
      lng < ((xj - xi) * (lat - yi)) / (yj - yi + 0.0) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}

export function isInsideDeliveryZones(
  deliveryLat: number,
  deliveryLng: number,
  restaurantLat: number,
  restaurantLng: number,
  zones: {
    maxDistanceKm: number | null;
    polygonGeo: unknown;
  }[],
): boolean {
  if (!zones.length) return true;

  for (const zone of zones) {
    if (zone.polygonGeo && typeof zone.polygonGeo === 'object') {
      const geo = zone.polygonGeo as {
        type?: string;
        coordinates?: number[][][] | number[][];
      };
      if (geo.type === 'Polygon' && Array.isArray(geo.coordinates?.[0])) {
        const ring = geo.coordinates[0] as number[][];
        if (pointInPolygon(deliveryLat, deliveryLng, ring)) return true;
      }
    }
    if (zone.maxDistanceKm != null) {
      const d = distanceKm(
        restaurantLat,
        restaurantLng,
        deliveryLat,
        deliveryLng,
      );
      if (d <= zone.maxDistanceKm) return true;
    }
  }
  return false;
}

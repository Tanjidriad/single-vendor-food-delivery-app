import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface RouteQuote {
  distanceKm: number;
  durationMinutes: number;
  source: 'google' | 'mapbox' | 'haversine';
}

@Injectable()
export class MapsService {
  private readonly logger = new Logger(MapsService.name);

  constructor(private config: ConfigService) {}

  async getRouteQuote(
    originLat: number,
    originLng: number,
    destLat: number,
    destLng: number,
  ): Promise<RouteQuote> {
    const apiKey = this.config.get<string>('googleMapsApiKey');
    const mapboxToken = this.config.get<string>('mapboxAccessToken');
    if (apiKey) {
      try {
        const url = new URL(
          'https://maps.googleapis.com/maps/api/distancematrix/json',
        );
        url.searchParams.set('origins', `${originLat},${originLng}`);
        url.searchParams.set('destinations', `${destLat},${destLng}`);
        url.searchParams.set('key', apiKey);
        url.searchParams.set('mode', 'driving');

        const res = await fetch(url.toString());
        const data = (await res.json()) as {
          rows?: { elements?: { status: string; distance?: { value: number }; duration?: { value: number } }[] }[];
        };
        const element = data.rows?.[0]?.elements?.[0];
        if (element?.status === 'OK' && element.distance && element.duration) {
          return {
            distanceKm: element.distance.value / 1000,
            durationMinutes: Math.ceil(element.duration.value / 60),
            source: 'google',
          };
        }
      } catch (err) {
        this.logger.warn(`Google Maps failed, using fallback: ${err}`);
      }
    }

    if (mapboxToken) {
      try {
        const url = new URL(
          `https://api.mapbox.com/directions/v5/mapbox/driving/${originLng},${originLat};${destLng},${destLat}`
        );
        url.searchParams.set('access_token', mapboxToken);
        url.searchParams.set('overview', 'false');

        const res = await fetch(url.toString());
        const data = (await res.json()) as {
          routes?: { distance: number; duration: number }[];
        };
        const route = data.routes?.[0];
        if (route && route.distance !== undefined && route.duration !== undefined) {
          return {
            distanceKm: route.distance / 1000,
            durationMinutes: Math.ceil(route.duration / 60),
            source: 'mapbox',
          };
        }
      } catch (err) {
        this.logger.warn(`Mapbox routing failed, using haversine: ${err}`);
      }
    }

    const distanceKm = this.haversineKm(originLat, originLng, destLat, destLng);
    return {
      distanceKm,
      durationMinutes: Math.max(5, Math.ceil(distanceKm * 4)),
      source: 'haversine',
    };
  }

  async geocode(address: string) {
    const apiKey = this.config.get<string>('googleMapsApiKey');
    const mapboxToken = this.config.get<string>('mapboxAccessToken');
    if (apiKey) {
      try {
        const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
        url.searchParams.set('address', address);
        url.searchParams.set('key', apiKey);
        const res = await fetch(url.toString());
        const data = (await res.json()) as {
          results?: { formatted_address: string; geometry: { location: { lat: number; lng: number } } }[];
        };
        const first = data.results?.[0];
        if (first) {
          return {
            address: first.formatted_address,
            latitude: first.geometry.location.lat,
            longitude: first.geometry.location.lng,
          };
        }
      } catch (err) {
        this.logger.warn(`Google geocoding failed: ${err}`);
      }
    }

    if (mapboxToken) {
      try {
        const url = new URL(`https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(address)}.json`);
        url.searchParams.set('access_token', mapboxToken);
        url.searchParams.set('limit', '1');
        const res = await fetch(url.toString());
        const data = (await res.json()) as {
          features?: { place_name: string; geometry: { coordinates: [number, number] } }[];
        };
        const first = data.features?.[0];
        if (first && first.geometry?.coordinates) {
          return {
            address: first.place_name,
            latitude: first.geometry.coordinates[1],
            longitude: first.geometry.coordinates[0],
          };
        }
      } catch (err) {
        this.logger.warn(`Mapbox geocoding failed: ${err}`);
      }
    }

    // Fallback to free OpenStreetMap Nominatim API
    this.logger.log('Using Nominatim for geocoding');
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', address);
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '1');
    const res = await fetch(url.toString(), {
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 FoodDeliveryApp/1.0' },
    });
    const data = await res.json() as { display_name?: string; lat?: string; lon?: string }[];
    const first = data?.[0];
    if (!first || !first.lat || !first.lon) {
      throw new BadRequestException('Address not found');
    }
    
    return {
      address: first.display_name || address,
      latitude: parseFloat(first.lat),
      longitude: parseFloat(first.lon),
    };
  }

  async reverseGeocode(lat: number, lng: number) {
    const apiKey = this.config.get<string>('googleMapsApiKey');
    const mapboxToken = this.config.get<string>('mapboxAccessToken');
    if (apiKey) {
      try {
        const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
        url.searchParams.set('latlng', `${lat},${lng}`);
        url.searchParams.set('key', apiKey);
        const res = await fetch(url.toString());
        const data = (await res.json()) as {
          results?: { formatted_address: string }[];
        };
        const first = data.results?.[0];
        if (first) {
          return { address: first.formatted_address, latitude: lat, longitude: lng };
        }
      } catch (err) {
        this.logger.warn(`Google reverse geocoding failed: ${err}`);
      }
    }

    if (mapboxToken) {
      try {
        const url = new URL(`https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json`);
        url.searchParams.set('access_token', mapboxToken);
        url.searchParams.set('limit', '1');
        const res = await fetch(url.toString());
        const data = (await res.json()) as {
          features?: { place_name: string }[];
        };
        const first = data.features?.[0];
        if (first) {
          return { address: first.place_name, latitude: lat, longitude: lng };
        }
      } catch (err) {
        this.logger.warn(`Mapbox reverse geocoding failed: ${err}`);
      }
    }

    // Fallback to free OpenStreetMap Nominatim API
    this.logger.log('Using Nominatim for reverse geocoding');
    const url = new URL('https://nominatim.openstreetmap.org/reverse');
    url.searchParams.set('lat', lat.toString());
    url.searchParams.set('lon', lng.toString());
    url.searchParams.set('format', 'json');
    const res = await fetch(url.toString(), {
      headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 FoodDeliveryApp/1.0' },
    });
    const data = await res.json() as { display_name?: string; error?: string };
    if (!data || data.error || !data.display_name) {
      throw new BadRequestException('Location not found');
    }

    return { address: data.display_name, latitude: lat, longitude: lng };
  }

  private haversineKm(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}

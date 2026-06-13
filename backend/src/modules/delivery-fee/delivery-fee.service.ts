import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { MapsService } from './maps.service';
import { isInsideDeliveryZones } from '../../common/utils/delivery-zone.util';
import { DeliveryFeeQuoteDto } from './dto/delivery-fee-quote.dto';

@Injectable()
export class DeliveryFeeService {
  constructor(
    private prisma: PrismaService,
    private maps: MapsService,
    private config: ConfigService,
  ) {}

  async quote(dto: DeliveryFeeQuoteDto) {
    const restaurant = await this.prisma.restaurant.findUnique({
      where: { id: dto.restaurantId },
      include: {
        deliveryFeeConfig: true,
        deliveryZones: { where: { isActive: true } },
      },
    });
    if (!restaurant) throw new NotFoundException('Restaurant not found');
    if (!restaurant.deliveryFeeConfig) {
      throw new BadRequestException('Delivery fee config missing');
    }

    const cfg = restaurant.deliveryFeeConfig;
    const originLat =
      restaurant.latitude || this.config.get<number>('restaurant.lat')!;
    const originLng =
      restaurant.longitude || this.config.get<number>('restaurant.lng')!;

    const route = await this.maps.getRouteQuote(
      originLat,
      originLng,
      dto.deliveryLat,
      dto.deliveryLng,
    );

    const activeZones = restaurant.deliveryZones ?? [];
    if (activeZones.length > 0) {
      const inZone = isInsideDeliveryZones(
        dto.deliveryLat,
        dto.deliveryLng,
        originLat,
        originLng,
        activeZones,
      );
      if (!inZone) {
        throw new BadRequestException(
          'Delivery address is outside active delivery zones',
        );
      }
    } else if (cfg.maxDeliveryKm && route.distanceKm > cfg.maxDeliveryKm) {
      throw new BadRequestException(
        `Delivery address is outside service area (${cfg.maxDeliveryKm} km max)`,
      );
    }

    let deliveryFee = cfg.baseFee + route.distanceKm * cfg.perKmFee;
    if (this.isPeakHour(cfg.peakHours)) {
      deliveryFee += cfg.peakHourSurcharge;
    }

    const subtotal = dto.subtotal ?? 0;
    if (
      cfg.freeDeliveryThreshold &&
      subtotal >= cfg.freeDeliveryThreshold
    ) {
      deliveryFee = 0;
    }

    const riderFee = deliveryFee;

    return {
      distanceKm: Math.round(route.distanceKm * 100) / 100,
      etaMinutes: route.durationMinutes,
      deliveryFee: Math.round(deliveryFee * 100) / 100,
      riderFee: Math.round(riderFee * 100) / 100,
      routeSource: route.source,
      currency: 'BDT',
    };
  }

  private isPeakHour(peakHours: unknown): boolean {
    if (!peakHours || !Array.isArray(peakHours)) return false;
    const now = new Date();
    const current = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    for (const slot of peakHours) {
      if (
        typeof slot === 'object' &&
        slot !== null &&
        'start' in slot &&
        'end' in slot
      ) {
        const { start, end } = slot as { start: string; end: string };
        if (current >= start && current <= end) return true;
      }
    }
    return false;
  }
}

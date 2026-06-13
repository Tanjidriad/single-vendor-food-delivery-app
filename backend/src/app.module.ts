import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { RequestIdMiddleware } from './common/middleware/request-id.middleware';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { APP_GUARD } from '@nestjs/core';
import { SentryModule } from '@sentry/nestjs/setup';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import configuration from './config/configuration';
import { validateEnv } from './config/env.validation';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { RealtimeModule } from './gateways/realtime.module';
import { PrismaModule } from './prisma/prisma.module';
import { AdminModule } from './modules/admin/admin.module';
import { AddressesModule } from './modules/addresses/addresses.module';
import { AuthModule } from './modules/auth/auth.module';
import { ComplaintsModule } from './modules/complaints/complaints.module';
import { CouponsModule } from './modules/coupons/coupons.module';
import { DevicesModule } from './modules/devices/devices.module';
import { DispatchModule } from './modules/dispatch/dispatch.module';
import { DeliveryFeeModule } from './modules/delivery-fee/delivery-fee.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { DevModule } from './modules/dev/dev.module';
import { HealthModule } from './modules/health/health.module';
import { MenuModule } from './modules/menu/menu.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { OrdersModule } from './modules/orders/orders.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { PrintEventsModule } from './modules/print-events/print-events.module';
import { EarningsModule } from './modules/earnings/earnings.module';
import { ReportsModule } from './modules/reports/reports.module';
import { RestaurantAdminModule } from './modules/restaurant-admin/restaurant-admin.module';
import { RestaurantModule } from './modules/restaurant/restaurant.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { RiderModule } from './modules/rider/rider.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { MediaModule } from './modules/media/media.module';
import { UsersModule } from './modules/users/users.module';

@Module({
  imports: [
    SentryModule.forRoot(),
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate: validateEnv,
    }),
    ScheduleModule.forRoot(),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 200 }]),
    PrismaModule,
    AdminModule,
    AuthModule,
    DevModule,
    HealthModule,
    UsersModule,
    DevicesModule,
    NotificationsModule,
    RestaurantModule,
    RestaurantAdminModule,
    MenuModule,
    DeliveryFeeModule,
    OrdersModule,
    DispatchModule,
    RiderModule,
    RealtimeModule,
    UploadsModule,
    MediaModule,
    AddressesModule,
    FavoritesModule,
    ReviewsModule,
    EarningsModule,
    ReportsModule,
    PaymentsModule,
    PrintEventsModule,
    CouponsModule,
    ComplaintsModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}

import { NestFactory } from '@nestjs/core';
import { AppModule } from './src/app.module';
import { OrdersService } from './src/modules/orders/orders.service';
import { PrismaService } from './src/prisma/prisma.service';
import { PlaceOrderDto } from './src/modules/orders/dto/place-order.dto';

async function run() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const ordersService = app.get(OrdersService);
  const prisma = app.get(PrismaService);
  
  const customer = await prisma.user.findFirst({ where: { role: 'CUSTOMER' } });
  const kitchen = await prisma.user.findFirst({ where: { role: 'KITCHEN' } });
  const menuItems = await prisma.menuItem.findMany({ where: { restaurantId: kitchen!.restaurantId! } });

  const dto = new PlaceOrderDto();
  dto.restaurantId = kitchen!.restaurantId!;
  dto.orderType = 'PICKUP' as any;
  dto.paymentMethod = 'COD' as any;
  dto.items = [{ menuItemId: menuItems[0].id, quantity: 1 }];
  dto.deliveryAddress = '123 Test';
  dto.deliveryLat = 40;
  dto.deliveryLng = -74;

  const order = await ordersService.placeOrder(customer!.id, dto);
  console.log("Order created:", order.id);

  await new Promise(resolve => setTimeout(resolve, 1000));
  await app.close();
}
run();

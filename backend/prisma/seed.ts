import {
  AddressLabel,
  PrismaClient,
  UserRole,
} from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

/** Stable Unsplash food photos for UI preview (no admin upload needed). */
const FOOD_IMAGES = {
  burger:
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
  pizza:
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
  pasta:
    'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80',
  noodles:
    'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=800&q=80',
  salad:
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
  chicken:
    'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&q=80',
  dessert:
    'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=800&q=80',
  drink:
    'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=800&q=80',
  fries:
    'https://images.unsplash.com/photo-1573080496219-bb080ddbb7db?w=800&q=80',
  banner1:
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80',
  banner2:
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1200&q=80',
  banner3:
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1200&q=80',
} as const;

const CATEGORY_IDS = {
  popular: '00000000-0000-4000-8000-000000000001',
  burgers: '00000000-0000-4000-8000-000000000010',
  pizza: '00000000-0000-4000-8000-000000000011',
  noodles: '00000000-0000-4000-8000-000000000012',
} as const;

const ITEM_IDS = {
  classicBurger: '00000000-0000-4000-8000-000000000002',
  doubleBurger: '00000000-0000-4000-8000-000000000020',
  crispyChicken: '00000000-0000-4000-8000-000000000021',
  margherita: '00000000-0000-4000-8000-000000000022',
  pepperoni: '00000000-0000-4000-8000-000000000023',
  ramen: '00000000-0000-4000-8000-000000000024',
  padThai: '00000000-0000-4000-8000-000000000025',
  caesarSalad: '00000000-0000-4000-8000-000000000026',
  loadedFries: '00000000-0000-4000-8000-000000000027',
  chocolateCake: '00000000-0000-4000-8000-000000000028',
  icedCoffee: '00000000-0000-4000-8000-000000000029',
} as const;

const WASABI_CATEGORY_IDS = {
  regularMomo: '10000000-0000-4000-8000-000000000001',
  momocola: '10000000-0000-4000-8000-000000000002',
  premiumMomo: '10000000-0000-4000-8000-000000000003',
  drinks: '10000000-0000-4000-8000-000000000004',
} as const;

const WASABI_ITEM_IDS = {
  chickenMomo: '10000000-0000-4000-8000-000000000101',
  mushroomMomo: '10000000-0000-4000-8000-000000000102',
  nagaMomo: '10000000-0000-4000-8000-000000000103',
  cheeseMomo: '10000000-0000-4000-8000-000000000104',
  chickenMomocola: '10000000-0000-4000-8000-000000000105',
  cheeseExplodeMomocola: '10000000-0000-4000-8000-000000000106',
  butterChickenMomo: '10000000-0000-4000-8000-000000000107',
  thaiSoupMomo: '10000000-0000-4000-8000-000000000108',
  icedLemonTea: '10000000-0000-4000-8000-000000000109',
  freshCola: '10000000-0000-4000-8000-000000000110',
} as const;

const WASABI_ADDON_IDS = {
  corn: '10000000-0000-4000-8000-000000000201',
  mushroom: '10000000-0000-4000-8000-000000000202',
  naga: '10000000-0000-4000-8000-000000000203',
  periPeri: '10000000-0000-4000-8000-000000000204',
  sriracha: '10000000-0000-4000-8000-000000000205',
  chiliOil: '10000000-0000-4000-8000-000000000206',
} as const;

const WASABI_BANNER_IDS = {
  momoLaunch: '10000000-0000-4000-8000-000000000301',
  comboDeal: '10000000-0000-4000-8000-000000000302',
  spicyPick: '10000000-0000-4000-8000-000000000303',
} as const;

async function upsertCategory(
  restaurantId: string,
  id: string,
  name: string,
  sortOrder: number,
  imageUrl: string,
) {
  return prisma.category.upsert({
    where: { id },
    update: { name, sortOrder, imageUrl, isActive: true },
    create: {
      id,
      restaurantId,
      name,
      sortOrder,
      imageUrl,
      isActive: true,
    },
  });
}

async function upsertMenuItem(
  restaurantId: string,
  categoryId: string,
  data: {
    id: string;
    name: string;
    description: string;
    price: number;
    imageUrl: string;
    isFeatured?: boolean;
    sortOrder?: number;
  },
) {
  return prisma.menuItem.upsert({
    where: { id: data.id },
    update: {
      name: data.name,
      description: data.description,
      price: data.price,
      imageUrl: data.imageUrl,
      isFeatured: data.isFeatured ?? false,
      isAvailable: true,
      sortOrder: data.sortOrder ?? 0,
      categoryId,
    },
    create: {
      id: data.id,
      restaurantId,
      categoryId,
      name: data.name,
      description: data.description,
      price: data.price,
      imageUrl: data.imageUrl,
      isFeatured: data.isFeatured ?? false,
      isAvailable: true,
      sortOrder: data.sortOrder ?? 0,
    },
  });
}

async function seedWasabiStorefront() {
  const restaurant = await prisma.restaurant.upsert({
    where: { slug: 'wasabi' },
    update: {
      name: 'WASABI',
      description: 'Authentic momos, spicy sauces, and quick comfort bowls',
      phone: '+8801700000100',
      email: 'hello@wasabi.test',
      latitude: 23.8103,
      longitude: 90.4125,
      addressLine: 'Dhaka, Bangladesh',
      city: 'Dhaka',
      country: 'BD',
      isActive: true,
    },
    create: {
      name: 'WASABI',
      slug: 'wasabi',
      description: 'Authentic momos, spicy sauces, and quick comfort bowls',
      phone: '+8801700000100',
      email: 'hello@wasabi.test',
      latitude: 23.8103,
      longitude: 90.4125,
      addressLine: 'Dhaka, Bangladesh',
      city: 'Dhaka',
      country: 'BD',
      settings: {
        create: {
          taxRatePercent: 5,
          packagingFee: 15,
          currency: 'BDT',
          minOrderAmount: 100,
          defaultPrepMinutes: 20,
          assignmentTimeoutSec: 45,
        },
      },
      deliveryFeeConfig: {
        create: {
          baseFee: 30,
          perKmFee: 12,
          peakHourSurcharge: 20,
          freeDeliveryThreshold: 800,
          maxDeliveryKm: 12,
        },
      },
    },
  });

  await prisma.restaurantSettings.upsert({
    where: { restaurantId: restaurant.id },
    update: {
      taxRatePercent: 5,
      packagingFee: 15,
      currency: 'BDT',
      minOrderAmount: 100,
      defaultPrepMinutes: 20,
      assignmentTimeoutSec: 45,
    },
    create: {
      restaurantId: restaurant.id,
      taxRatePercent: 5,
      packagingFee: 15,
      currency: 'BDT',
      minOrderAmount: 100,
      defaultPrepMinutes: 20,
      assignmentTimeoutSec: 45,
    },
  });

  await prisma.deliveryFeeConfig.upsert({
    where: { restaurantId: restaurant.id },
    update: {
      baseFee: 30,
      perKmFee: 12,
      peakHourSurcharge: 20,
      freeDeliveryThreshold: 800,
      maxDeliveryKm: 12,
    },
    create: {
      restaurantId: restaurant.id,
      baseFee: 30,
      perKmFee: 12,
      peakHourSurcharge: 20,
      freeDeliveryThreshold: 800,
      maxDeliveryKm: 12,
    },
  });

  const regularMomo = await upsertCategory(
    restaurant.id,
    WASABI_CATEGORY_IDS.regularMomo,
    'Regular Momo',
    1,
    FOOD_IMAGES.chicken,
  );
  const momocola = await upsertCategory(
    restaurant.id,
    WASABI_CATEGORY_IDS.momocola,
    'Momocola',
    2,
    FOOD_IMAGES.drink,
  );
  const premiumMomo = await upsertCategory(
    restaurant.id,
    WASABI_CATEGORY_IDS.premiumMomo,
    'Premium Momo',
    3,
    FOOD_IMAGES.noodles,
  );
  const drinks = await upsertCategory(
    restaurant.id,
    WASABI_CATEGORY_IDS.drinks,
    'Drinks',
    4,
    FOOD_IMAGES.drink,
  );

  const wasabiItems = [
    {
      id: WASABI_ITEM_IDS.chickenMomo,
      categoryId: regularMomo.id,
      name: 'Chicken Momo',
      description: 'Steamed chicken dumplings with house momo sauce',
      price: 150,
      imageUrl:
        'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=800&q=80',
      isFeatured: true,
      sortOrder: 1,
    },
    {
      id: WASABI_ITEM_IDS.mushroomMomo,
      categoryId: regularMomo.id,
      name: 'Mushroom Momo',
      description: 'Juicy mushroom momo with fresh herbs',
      price: 190,
      imageUrl:
        'https://images.unsplash.com/photo-1541696432-82c6da8ce7bf?w=800&q=80',
      isFeatured: false,
      sortOrder: 2,
    },
    {
      id: WASABI_ITEM_IDS.nagaMomo,
      categoryId: regularMomo.id,
      name: 'Naga Momo',
      description: 'Extra spicy chicken momo for heat lovers',
      price: 190,
      imageUrl: FOOD_IMAGES.chicken,
      isFeatured: true,
      sortOrder: 3,
    },
    {
      id: WASABI_ITEM_IDS.cheeseMomo,
      categoryId: regularMomo.id,
      name: 'Cheese Momo',
      description: 'Creamy cheese-filled momo with mild sauce',
      price: 210,
      imageUrl: FOOD_IMAGES.dessert,
      isFeatured: false,
      sortOrder: 4,
    },
    {
      id: WASABI_ITEM_IDS.chickenMomocola,
      categoryId: momocola.id,
      name: 'Chicken Momocola',
      description: 'Chicken momo combo served with cola',
      price: 210,
      imageUrl:
        'https://images.unsplash.com/photo-1525755662778-989d0524087e?w=800&q=80',
      isFeatured: true,
      sortOrder: 1,
    },
    {
      id: WASABI_ITEM_IDS.cheeseExplodeMomocola,
      categoryId: momocola.id,
      name: 'Cheese Explode Momocola',
      description: 'Cheesy momo combo with chilled cola',
      price: 290,
      imageUrl: FOOD_IMAGES.drink,
      isFeatured: false,
      sortOrder: 2,
    },
    {
      id: WASABI_ITEM_IDS.butterChickenMomo,
      categoryId: premiumMomo.id,
      name: 'Butter Chicken Momo',
      description: 'Momo tossed in rich butter chicken gravy',
      price: 270,
      imageUrl: FOOD_IMAGES.noodles,
      isFeatured: true,
      sortOrder: 1,
    },
    {
      id: WASABI_ITEM_IDS.thaiSoupMomo,
      categoryId: premiumMomo.id,
      name: 'Thai Soup Momo',
      description: 'Warm Thai-style broth with soft momo',
      price: 260,
      imageUrl: FOOD_IMAGES.noodles,
      isFeatured: true,
      sortOrder: 2,
    },
    {
      id: WASABI_ITEM_IDS.icedLemonTea,
      categoryId: drinks.id,
      name: 'Iced Lemon Tea',
      description: 'Refreshing lemon tea for spicy momo meals',
      price: 90,
      imageUrl: FOOD_IMAGES.drink,
      isFeatured: false,
      sortOrder: 1,
    },
    {
      id: WASABI_ITEM_IDS.freshCola,
      categoryId: drinks.id,
      name: 'Fresh Cola',
      description: 'Cold cola served with WASABI combos',
      price: 60,
      imageUrl: FOOD_IMAGES.drink,
      isFeatured: false,
      sortOrder: 2,
    },
  ];

  for (const item of wasabiItems) {
    await upsertMenuItem(restaurant.id, item.categoryId, item);
  }

  const addonDefs = [
    { id: WASABI_ADDON_IDS.corn, name: 'Corn', price: 30 },
    { id: WASABI_ADDON_IDS.mushroom, name: 'Mushroom', price: 30 },
    { id: WASABI_ADDON_IDS.naga, name: 'Naga', price: 30 },
    { id: WASABI_ADDON_IDS.periPeri, name: 'Peri Peri Sauce', price: 30 },
    { id: WASABI_ADDON_IDS.sriracha, name: 'Sriracha Sauce', price: 30 },
    { id: WASABI_ADDON_IDS.chiliOil, name: 'Chili Oil', price: 30 },
  ];

  for (const addon of addonDefs) {
    await prisma.addon.upsert({
      where: { id: addon.id },
      update: {
        name: addon.name,
        price: addon.price,
        isActive: true,
      },
      create: {
        id: addon.id,
        restaurantId: restaurant.id,
        name: addon.name,
        price: addon.price,
        isActive: true,
      },
    });
  }

  for (const itemId of [
    WASABI_ITEM_IDS.chickenMomo,
    WASABI_ITEM_IDS.mushroomMomo,
    WASABI_ITEM_IDS.nagaMomo,
    WASABI_ITEM_IDS.cheeseMomo,
    WASABI_ITEM_IDS.butterChickenMomo,
    WASABI_ITEM_IDS.thaiSoupMomo,
  ]) {
    for (const addonId of Object.values(WASABI_ADDON_IDS)) {
      await prisma.menuItemAddon.upsert({
        where: { menuItemId_addonId: { menuItemId: itemId, addonId } },
        update: {},
        create: { menuItemId: itemId, addonId },
      });
    }
  }

  for (let day = 0; day <= 6; day++) {
    await prisma.operatingHour.upsert({
      where: {
        restaurantId_dayOfWeek: { restaurantId: restaurant.id, dayOfWeek: day },
      },
      update: { openTime: '11:00', closeTime: '23:00', isClosed: false },
      create: {
        restaurantId: restaurant.id,
        dayOfWeek: day,
        openTime: '11:00',
        closeTime: '23:00',
      },
    });
  }

  const bannerDefs = [
    {
      id: WASABI_BANNER_IDS.momoLaunch,
      title: 'Fresh momo is live',
      imageUrl: FOOD_IMAGES.banner1,
      sortOrder: 1,
    },
    {
      id: WASABI_BANNER_IDS.comboDeal,
      title: 'Momocola combo deal',
      imageUrl: FOOD_IMAGES.banner2,
      sortOrder: 2,
    },
    {
      id: WASABI_BANNER_IDS.spicyPick,
      title: 'Try the spicy naga momo',
      imageUrl: FOOD_IMAGES.banner3,
      sortOrder: 3,
    },
  ];

  for (const b of bannerDefs) {
    await prisma.banner.upsert({
      where: { id: b.id },
      update: {
        title: b.title,
        imageUrl: b.imageUrl,
        isActive: true,
        sortOrder: b.sortOrder,
      },
      create: {
        id: b.id,
        restaurantId: restaurant.id,
        title: b.title,
        imageUrl: b.imageUrl,
        isActive: true,
        sortOrder: b.sortOrder,
      },
    });
  }

  return {
    restaurant,
    categoryCount: 4,
    itemCount: wasabiItems.length,
    featuredCount: wasabiItems.filter((item) => item.isFeatured).length,
    bannerCount: bannerDefs.length,
  };
}

async function main() {
  const passwordHash = await bcrypt.hash('Password123!', 12);

  const restaurant = await prisma.restaurant.upsert({
    where: { slug: 'demo-kitchen' },
    update: {},
    create: {
      name: 'Demo Kitchen',
      slug: 'demo-kitchen',
      description: 'Single-brand demo restaurant',
      phone: '+8801700000000',
      email: 'hello@demokitchen.com',
      latitude: 23.8103,
      longitude: 90.4125,
      addressLine: 'Dhaka, Bangladesh',
      city: 'Dhaka',
      country: 'BD',
      settings: {
        create: {
          taxRatePercent: 5,
          packagingFee: 15,
          currency: 'BDT',
          minOrderAmount: 100,
          defaultPrepMinutes: 20,
          assignmentTimeoutSec: 45,
        },
      },
      deliveryFeeConfig: {
        create: {
          baseFee: 30,
          perKmFee: 12,
          peakHourSurcharge: 20,
          freeDeliveryThreshold: 800,
          maxDeliveryKm: 12,
        },
      },
    },
  });

  await prisma.user.upsert({
    where: { email: 'owner@demokitchen.com' },
    update: {},
    create: {
      email: 'owner@demokitchen.com',
      phone: '+8801700000001',
      passwordHash,
      role: UserRole.OWNER,
      restaurantId: restaurant.id,
      staffProfile: {
        create: {
          restaurantId: restaurant.id,
          fullName: 'Restaurant Owner',
          jobTitle: 'Owner',
        },
      },
    },
  });

  await prisma.user.upsert({
    where: { email: 'kitchen@demokitchen.com' },
    update: {},
    create: {
      email: 'kitchen@demokitchen.com',
      passwordHash,
      role: UserRole.KITCHEN,
      restaurantId: restaurant.id,
      staffProfile: {
        create: {
          restaurantId: restaurant.id,
          fullName: 'Kitchen Staff',
          jobTitle: 'Kitchen',
        },
      },
    },
  });

  await prisma.user.upsert({
    where: { phone: '+8801700000002' },
    update: {},
    create: {
      phone: '+8801700000002',
      passwordHash,
      role: UserRole.RIDER,
      riderProfile: {
        create: {
          fullName: 'Demo Rider',
          vehicleType: 'bike',
          approvalStatus: 'APPROVED',
          isOnline: true,
        },
      },
    },
  });

  const customer = await prisma.user.upsert({
    where: { email: 'customer@example.com' },
    update: {},
    create: {
      email: 'customer@example.com',
      phone: '+8801700000003',
      passwordHash,
      role: UserRole.CUSTOMER,
      customerProfile: {
        create: { fullName: 'Demo Customer' },
      },
    },
  });

  // Default delivery address (near Demo Kitchen — used for checkout / delivery quotes)
  const customerAddressLine1 = 'House 12, Road 5, Dhaka';
  const customerLat = 23.815;
  const customerLng = 90.42;
  const existingCustomerAddress = await prisma.address.findFirst({
    where: { userId: customer.id, line1: customerAddressLine1 },
  });
  if (existingCustomerAddress) {
    await prisma.address.update({
      where: { id: existingCustomerAddress.id },
      data: {
        label: AddressLabel.HOME,
        city: 'Dhaka',
        country: 'BD',
        latitude: customerLat,
        longitude: customerLng,
        isDefault: true,
      },
    });
    await prisma.address.updateMany({
      where: { userId: customer.id, id: { not: existingCustomerAddress.id } },
      data: { isDefault: false },
    });
  } else {
    await prisma.address.updateMany({
      where: { userId: customer.id },
      data: { isDefault: false },
    });
    await prisma.address.create({
      data: {
        userId: customer.id,
        label: AddressLabel.HOME,
        line1: customerAddressLine1,
        city: 'Dhaka',
        country: 'BD',
        latitude: customerLat,
        longitude: customerLng,
        isDefault: true,
      },
    });
  }

  const popular = await upsertCategory(
    restaurant.id,
    CATEGORY_IDS.popular,
    'Popular',
    1,
    FOOD_IMAGES.fries,
  );
  const burgers = await upsertCategory(
    restaurant.id,
    CATEGORY_IDS.burgers,
    'Burgers',
    2,
    FOOD_IMAGES.burger,
  );
  const pizza = await upsertCategory(
    restaurant.id,
    CATEGORY_IDS.pizza,
    'Pizza',
    3,
    FOOD_IMAGES.pizza,
  );
  const noodles = await upsertCategory(
    restaurant.id,
    CATEGORY_IDS.noodles,
    'Noodles',
    4,
    FOOD_IMAGES.noodles,
  );

  const items = [
    {
      id: ITEM_IDS.classicBurger,
      categoryId: burgers.id,
      name: 'Classic Burger',
      description: 'Beef patty, cheese, house sauce',
      price: 350,
      imageUrl: FOOD_IMAGES.burger,
      isFeatured: true,
      sortOrder: 1,
    },
    {
      id: ITEM_IDS.doubleBurger,
      categoryId: burgers.id,
      name: 'Double Smash Burger',
      description: 'Two patties, caramelized onions',
      price: 480,
      imageUrl: FOOD_IMAGES.burger,
      isFeatured: true,
      sortOrder: 2,
    },
    {
      id: ITEM_IDS.crispyChicken,
      categoryId: popular.id,
      name: 'Crispy Chicken Box',
      description: 'Spicy chicken with fries',
      price: 420,
      imageUrl: FOOD_IMAGES.chicken,
      isFeatured: true,
      sortOrder: 2,
    },
    {
      id: ITEM_IDS.margherita,
      categoryId: pizza.id,
      name: 'Margherita Pizza',
      description: 'Fresh mozzarella and basil',
      price: 550,
      imageUrl: FOOD_IMAGES.pizza,
      isFeatured: true,
      sortOrder: 1,
    },
    {
      id: ITEM_IDS.pepperoni,
      categoryId: pizza.id,
      name: 'Pepperoni Feast',
      description: 'Loaded pepperoni and cheese',
      price: 620,
      imageUrl: FOOD_IMAGES.pizza,
      isFeatured: false,
      sortOrder: 2,
    },
    {
      id: ITEM_IDS.ramen,
      categoryId: noodles.id,
      name: 'Tonkotsu Ramen',
      description: 'Rich pork broth, soft egg',
      price: 390,
      imageUrl: FOOD_IMAGES.noodles,
      isFeatured: true,
      sortOrder: 1,
    },
    {
      id: ITEM_IDS.padThai,
      categoryId: noodles.id,
      name: 'Pad Thai',
      description: 'Tamarind noodles with peanuts',
      price: 360,
      imageUrl: FOOD_IMAGES.noodles,
      isFeatured: false,
      sortOrder: 2,
    },
    {
      id: ITEM_IDS.caesarSalad,
      categoryId: popular.id,
      name: 'Caesar Salad',
      description: 'Romaine, parmesan, croutons',
      price: 280,
      imageUrl: FOOD_IMAGES.salad,
      isFeatured: false,
      sortOrder: 3,
    },
    {
      id: ITEM_IDS.loadedFries,
      categoryId: popular.id,
      name: 'Loaded Fries',
      description: 'Cheese sauce, bacon bits',
      price: 220,
      imageUrl: FOOD_IMAGES.fries,
      isFeatured: true,
      sortOrder: 4,
    },
    {
      id: ITEM_IDS.chocolateCake,
      categoryId: popular.id,
      name: 'Chocolate Lava Cake',
      description: 'Warm center, vanilla scoop',
      price: 260,
      imageUrl: FOOD_IMAGES.dessert,
      isFeatured: false,
      sortOrder: 5,
    },
    {
      id: ITEM_IDS.icedCoffee,
      categoryId: popular.id,
      name: 'Iced Caramel Coffee',
      description: 'Cold brew with caramel',
      price: 180,
      imageUrl: FOOD_IMAGES.drink,
      isFeatured: true,
      sortOrder: 6,
    },
  ];

  for (const item of items) {
    await upsertMenuItem(restaurant.id, item.categoryId, item);
  }

  const cheeseAddon = await prisma.addon.upsert({
    where: { id: '00000000-0000-4000-8000-000000000003' },
    update: {},
    create: {
      id: '00000000-0000-4000-8000-000000000003',
      restaurantId: restaurant.id,
      name: 'Extra Cheese',
      price: 50,
    },
  });

  await prisma.menuItemAddon.upsert({
    where: {
      menuItemId_addonId: {
        menuItemId: ITEM_IDS.classicBurger,
        addonId: cheeseAddon.id,
      },
    },
    update: {},
    create: { menuItemId: ITEM_IDS.classicBurger, addonId: cheeseAddon.id },
  });

  await prisma.coupon.upsert({
    where: {
      restaurantId_code: {
        restaurantId: restaurant.id,
        code: 'WELCOME10',
      },
    },
    update: {},
    create: {
      restaurantId: restaurant.id,
      code: 'WELCOME10',
      discountType: 'PERCENT',
      discountValue: 10,
      minOrderAmount: 200,
      isActive: true,
    },
  });

  for (let day = 0; day <= 6; day++) {
    await prisma.operatingHour.upsert({
      where: {
        restaurantId_dayOfWeek: { restaurantId: restaurant.id, dayOfWeek: day },
      },
      update: {},
      create: {
        restaurantId: restaurant.id,
        dayOfWeek: day,
        openTime: '10:00',
        closeTime: '23:00',
      },
    });
  }

  const bannerDefs = [
    {
      id: '00000000-0000-4000-8000-000000000030',
      title: 'Free delivery weekend',
      imageUrl: FOOD_IMAGES.banner1,
      sortOrder: 1,
    },
    {
      id: '00000000-0000-4000-8000-000000000031',
      title: '20% off burgers',
      imageUrl: FOOD_IMAGES.banner2,
      sortOrder: 2,
    },
    {
      id: '00000000-0000-4000-8000-000000000032',
      title: 'New ramen bowl',
      imageUrl: FOOD_IMAGES.banner3,
      sortOrder: 3,
    },
  ];

  for (const b of bannerDefs) {
    await prisma.banner.upsert({
      where: { id: b.id },
      update: {
        title: b.title,
        imageUrl: b.imageUrl,
        isActive: true,
        sortOrder: b.sortOrder,
      },
      create: {
        id: b.id,
        restaurantId: restaurant.id,
        title: b.title,
        imageUrl: b.imageUrl,
        isActive: true,
        sortOrder: b.sortOrder,
      },
    });
  }

  console.log('Seed complete (demo menu for UI preview):');
  console.log(`  Restaurant slug: ${restaurant.slug}`);
  console.log(`  Categories: Popular, Burgers, Pizza, Noodles`);
  console.log(`  Menu items: ${items.length} (with food images)`);
  console.log(`  Featured items: ${items.filter((i) => i.isFeatured).length}`);
  console.log(`  Banners: ${bannerDefs.length}`);
  console.log('  Customer app uses slug: demo-kitchen (AppConfig.restaurantSlug)');
  console.log('  Owner login: owner@demokitchen.com / Password123!');

  const wasabi = await seedWasabiStorefront();
  console.log('Seed complete (WASABI customer web menu):');
  console.log(`  Restaurant slug: ${wasabi.restaurant.slug}`);
  console.log(`  Categories: ${wasabi.categoryCount}`);
  console.log(`  Menu items: ${wasabi.itemCount} (with addons and food images)`);
  console.log(`  Featured items: ${wasabi.featuredCount}`);
  console.log(`  Banners: ${wasabi.bannerCount}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

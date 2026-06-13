import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding WASABI Menu...');

  // 1. Get or create the main restaurant
  let restaurant = await prisma.restaurant.findFirst();
  if (!restaurant) {
    restaurant = await prisma.restaurant.create({
      data: {
        name: 'WASABI',
        slug: 'wasabi',
        description: 'Authentic Momos and more',
      },
    });
  }

  // 2. We skip deleting existing data to preserve order history constraints

  // 3. Create Add-ons & Sauces
  const addonCorn = await prisma.addon.create({ data: { restaurantId: restaurant.id, name: 'Corn', price: 30 } });
  const addonMushroom = await prisma.addon.create({ data: { restaurantId: restaurant.id, name: 'Mushroom', price: 30 } });
  const addonNaga = await prisma.addon.create({ data: { restaurantId: restaurant.id, name: 'Naga', price: 30 } });
  
  const saucePeriPeri = await prisma.addon.create({ data: { restaurantId: restaurant.id, name: 'Peri Peri Sauce', price: 30 } });
  const sauceSriracha = await prisma.addon.create({ data: { restaurantId: restaurant.id, name: 'Sriracha Sauce', price: 30 } });
  const sauceChiliOil = await prisma.addon.create({ data: { restaurantId: restaurant.id, name: 'Chili Oil', price: 30 } });

  const standardAddons = [
    { addonId: addonCorn.id }, { addonId: addonMushroom.id }, { addonId: addonNaga.id },
    { addonId: saucePeriPeri.id }, { addonId: sauceSriracha.id }, { addonId: sauceChiliOil.id }
  ];

  // 4. Create Categories
  const catRegular = await prisma.category.create({ data: { restaurantId: restaurant.id, name: 'Regular Momo', sortOrder: 1 } });
  const catMomocola = await prisma.category.create({ data: { restaurantId: restaurant.id, name: 'Momocola', sortOrder: 2 } });
  const catPremium = await prisma.category.create({ data: { restaurantId: restaurant.id, name: 'Premium Momo', sortOrder: 3 } });

  // 5. Create Menu Items - Regular Momo
  await prisma.menuItem.create({
    data: {
      restaurantId: restaurant.id,
      categoryId: catRegular.id,
      name: 'Chicken Momo',
      price: 150,
      imageUrl: 'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?q=80&w=600&auto=format&fit=crop',
      addons: { create: standardAddons }
    }
  });

  await prisma.menuItem.create({
    data: {
      restaurantId: restaurant.id,
      categoryId: catRegular.id,
      name: 'Mushroom Momo',
      price: 190,
      imageUrl: 'https://images.unsplash.com/photo-1541696432-82c6da8ce7bf?q=80&w=600&auto=format&fit=crop',
      addons: { create: standardAddons }
    }
  });

  await prisma.menuItem.create({
    data: {
      restaurantId: restaurant.id,
      categoryId: catRegular.id,
      name: 'Naga Momo',
      price: 190,
      isFeatured: true,
      addons: { create: standardAddons }
    }
  });

  await prisma.menuItem.create({
    data: {
      restaurantId: restaurant.id,
      categoryId: catRegular.id,
      name: 'Cheese Momo',
      price: 210,
      addons: { create: standardAddons }
    }
  });

  // 6. Create Menu Items - Momocola
  await prisma.menuItem.create({
    data: {
      restaurantId: restaurant.id,
      categoryId: catMomocola.id,
      name: 'Chicken Momocola',
      description: 'Served with Mojo or Fresh Cola',
      price: 210,
      imageUrl: 'https://images.unsplash.com/photo-1626804475297-41609ea004eb?q=80&w=600&auto=format&fit=crop',
    }
  });

  await prisma.menuItem.create({
    data: {
      restaurantId: restaurant.id,
      categoryId: catMomocola.id,
      name: 'Cheese Explode Momocola',
      description: 'Served with Mojo or Fresh Cola',
      price: 290,
    }
  });

  // 7. Create Menu Items - Premium Momo
  await prisma.menuItem.create({
    data: {
      restaurantId: restaurant.id,
      categoryId: catPremium.id,
      name: 'Butter Chicken Momo',
      price: 270,
      isFeatured: true,
      addons: { create: standardAddons }
    }
  });

  console.log('Successfully seeded WASABI menu!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

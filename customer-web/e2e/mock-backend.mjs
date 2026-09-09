import { createServer } from "node:http";

const user = {
  id: "customer-e2e",
  email: "customer@example.com",
  phone: "+8801700000000",
  role: "CUSTOMER",
  fullName: "Mobile Customer",
};

const restaurant = {
  id: "restaurant-e2e",
  name: "Wasabi Momo House",
  slug: "wasabi",
  description: "Fresh momo, made to order.",
  phone: "+8801700000010",
  email: "hello@wasabi.test",
  addressLine: "House 12, Momo Road",
  city: "Dhaka",
  country: "Bangladesh",
  latitude: 23.7465,
  longitude: 90.376,
  operatingHours: [0, 1, 2, 3, 4, 5, 6].map((dayOfWeek) => ({
    dayOfWeek,
    openTime: "11:00",
    closeTime: "23:00",
    isClosed: false,
  })),
  settings: {
    taxRatePercent: 5,
    packagingFee: 10,
    currency: "BDT",
    minOrderAmount: 100,
    defaultPrepMinutes: 20,
  },
};

const order = {
  id: "order-e2e",
  orderNumber: "W-E2E-001",
  dailySerial: 1,
  status: "PLACED",
  orderType: "DELIVERY",
  paymentMethod: "ONLINE",
  paymentStatus: "PENDING",
  customerName: user.fullName,
  customerPhone: user.phone,
  deliveryAddress: "House 1, Test Road, Dhaka",
  subtotal: 240,
  discountAmount: 0,
  taxAmount: 12,
  packagingFee: 10,
  deliveryFee: 50,
  grandTotal: 312,
  placedAt: new Date().toISOString(),
  createdAt: new Date().toISOString(),
  items: [
    {
      id: "order-item-e2e",
      name: "Chicken Momo",
      unitPrice: 120,
      quantity: 2,
      lineTotal: 240,
      addons: [],
    },
  ],
  statusHistory: [],
  restaurant,
};

function json(response, status, value) {
  response.writeHead(status, {
    "content-type": "application/json",
    "cache-control": "no-store",
  });
  response.end(JSON.stringify(value));
}

async function readJson(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  if (!chunks.length) return {};
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

function authenticated(request) {
  return /^Bearer (access-e2e|access-rotated)$/.test(
    request.headers.authorization ?? ""
  );
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url ?? "/", "http://127.0.0.1:4010");
  const path = url.pathname;

  if (path === "/health") return json(response, 200, { status: "ok" });

  if (path === "/api/v1/auth/login" && request.method === "POST") {
    const body = await readJson(request);
    if (body.password !== "Password123!") {
      return json(response, 401, { message: "Invalid credentials" });
    }
    return json(response, 200, {
      accessToken: "access-e2e",
      refreshToken: "refresh-e2e",
      user,
    });
  }

  if (path === "/api/v1/auth/refresh" && request.method === "POST") {
    const body = await readJson(request);
    if (body.refreshToken !== "refresh-e2e") {
      return json(response, 401, { message: "Invalid refresh token" });
    }
    return json(response, 200, {
      accessToken: "access-rotated",
      refreshToken: "refresh-rotated",
      user,
    });
  }

  if (path === "/api/v1/auth/logout" && request.method === "POST") {
    return json(response, authenticated(request) ? 200 : 401, { success: true });
  }

  if (path === "/api/v1/auth/otp/send" && request.method === "POST") {
    return json(response, 200, { success: true });
  }

  if (path === "/api/v1/auth/forgot-password/reset" && request.method === "POST") {
    const body = await readJson(request);
    return body.code === "123456"
      ? json(response, 200, { success: true })
      : json(response, 400, { message: "Invalid reset code" });
  }

  if (path === "/api/v1/users/me") {
    return authenticated(request)
      ? json(response, 200, user)
      : json(response, 401, { message: "Authentication required" });
  }

  if (path === "/api/v1/restaurant/slug/wasabi") {
    return json(response, 200, restaurant);
  }

  if (path === "/api/v1/menu/restaurant/restaurant-e2e") {
    return json(response, 200, [
      {
        id: "category-e2e",
        name: "Momo",
        items: [
          {
            id: "momo-e2e",
            name: "Chicken Momo",
            description: "Steamed and juicy",
            price: 120,
            isAvailable: true,
            isFeatured: true,
            addons: [
              {
                addon: {
                  id: "addon-e2e",
                  name: "Chilli oil",
                  price: 20,
                },
              },
            ],
          },
        ],
      },
    ]);
  }

  if (path.endsWith("/banners")) {
    return json(response, 200, [
      {
        id: "banner-e2e",
        title: "Fresh momo, folded today",
        imageUrl: "/img/momo-steamed.jpg",
        linkUrl: "/menu#menu-list",
        sortOrder: 1,
      },
    ]);
  }

  if (path.endsWith("/featured")) {
    return json(response, 200, [
      {
        id: "momo-e2e",
        name: "Chicken Momo",
        description: "Steamed and juicy",
        price: 120,
        isAvailable: true,
        isFeatured: true,
      },
    ]);
  }

  if (path.startsWith("/api/v1/reviews/")) {
    return json(response, 200, []);
  }

  if (path === "/api/v1/favorites") {
    if (!authenticated(request)) return json(response, 401, { message: "Authentication required" });
    return json(response, 200, [
      {
        id: "favorite-e2e",
        createdAt: new Date().toISOString(),
        menuItem: {
          id: "momo-e2e",
          name: "Chicken Momo",
          description: "Steamed and juicy",
          price: 120,
          isAvailable: true,
          isFeatured: true,
          addons: [],
        },
      },
    ]);
  }

  if (path === "/api/v1/notifications") {
    if (!authenticated(request)) return json(response, 401, { message: "Authentication required" });
    return json(response, 200, [
      {
        id: "notification-e2e",
        title: "Order received",
        body: "The kitchen has your momo order.",
        type: "ORDER",
        orderId: order.id,
        readAt: null,
        createdAt: new Date().toISOString(),
      },
    ]);
  }

  if (path === "/api/v1/complaints/me") {
    if (!authenticated(request)) return json(response, 401, { message: "Authentication required" });
    return json(response, 200, []);
  }

  if (path === "/api/v1/addresses") {
    if (!authenticated(request)) return json(response, 401, { message: "Authentication required" });
    return json(response, 200, [
      {
        id: "address-e2e",
        label: "HOME",
        line1: "House 1, Test Road",
        city: "Dhaka",
        latitude: 23.75,
        longitude: 90.38,
        isDefault: true,
      },
    ]);
  }

  if (path === "/api/v1/delivery-fee/quote" && request.method === "POST") {
    return json(response, 200, {
      distanceKm: 2.3,
      etaMinutes: 24,
      deliveryFee: 50,
      riderFee: 35,
      routeSource: "mock",
      currency: "BDT",
    });
  }

  if (path === "/api/v1/coupons/public") {
    return json(response, 200, [
      {
        id: "coupon-e2e",
        code: "MOBILE10",
        description: "Mobile launch offer",
        discountType: "PERCENT",
        discountValue: 10,
        minOrderAmount: 200,
      },
    ]);
  }

  if (path === "/api/v1/orders" && request.method === "POST") {
    const body = await readJson(request);
    return json(response, 201, { ...order, orderType: body.orderType, paymentMethod: body.paymentMethod });
  }

  if (path === "/api/v1/orders" && request.method === "GET") {
    return json(response, 200, [order]);
  }

  if (path === "/api/v1/orders/order-e2e") {
    return json(response, 200, order);
  }

  if (path === "/api/v1/payments/orders/order-e2e/online/initiate" && request.method === "POST") {
    return json(response, 200, {
      orderId: order.id,
      gateway: "bkash",
      amount: order.grandTotal,
      currency: "BDT",
      status: "PENDING",
      paymentId: "payment-e2e",
      checkoutUrl: "https://sandbox.bka.sh/checkout/payment-e2e",
      callbackUrl: "http://localhost:3101/payment/callback?orderId=order-e2e",
    });
  }

  if (path === "/api/v1/payments/orders/order-e2e/online/execute" && request.method === "POST") {
    const body = await readJson(request);
    return body.paymentId === "payment-e2e"
      ? json(response, 200, {
          orderId: order.id,
          gateway: "bkash",
          status: "PAID",
          transactionId: "trx-e2e",
          paidAt: new Date().toISOString(),
        })
      : json(response, 400, { message: "Payment id mismatch" });
  }

  return json(response, 404, { message: `No mock for ${request.method} ${path}` });
});

server.listen(4010, "127.0.0.1");

import fetch from 'node-fetch'; // Requires node-fetch if Node < 18, but Node 18+ has fetch built-in.

const BASE = process.env.API_BASE ?? 'http://localhost:3000/api/v1';
const PASSWORD = 'Password123!';

const RESTAURANT_ID = '00000000-0000-4000-8000-000000000010';
const MENU_ITEM_ID = '00000000-0000-4000-8000-000000000002';
const ADDON_ID = '00000000-0000-4000-8000-000000000003';

async function req(method, path, { token, body } = {}) {
  const url = new URL(path.startsWith('http') ? path : `${BASE}${path}`);
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers['Content-Type'] = 'application/json';

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  
  const text = await res.text();
  try {
    return text ? JSON.parse(text) : null;
  } catch {
    return text;
  }
}

async function login(creds) {
  const res = await req('POST', '/auth/login', { body: creds });
  if (!res?.accessToken) {
    console.error('Login failed for', creds.email, res);
  }
  return res?.accessToken;
}

async function main() {
  console.log('Logging in as customer and owner...');
  const customerToken = await login({ email: 'customer@example.com', password: PASSWORD });
  const ownerToken = await login({ email: 'owner@demokitchen.com', password: PASSWORD });

  const slugData = await req('GET', '/restaurant/slug/demo-kitchen');
  const restaurantId = slugData?.id ?? RESTAURANT_ID;

  if (!customerToken || !ownerToken) {
    console.error('Failed to login. Is the backend running on http://localhost:3000?');
    process.exit(1);
  }

  console.log(`Using restaurant ID: ${restaurantId}`);

  console.log('Ensuring restaurant is open for orders...');
  const currentDay = new Date().getDay() || 7; // 1-7 for Mon-Sun
  await req('POST', `/admin/restaurant/operating-hours/${currentDay}`, {
    token: ownerToken,
    body: { openTime: '00:00', closeTime: '23:59', isClosed: false },
  });
  
  await req('PATCH', '/admin/restaurant/profile', {
    token: ownerToken,
    body: { isActive: true },
  });

  console.log('Placing a new order to trigger KDS alert...');
  const order = await req('POST', '/orders', {
    token: customerToken,
    body: {
      restaurantId,
      orderType: 'DELIVERY',
      paymentMethod: 'COD',
      deliveryAddress: 'House 12, Dhaka',
      deliveryLat: 23.815,
      deliveryLng: 90.42,
      items: [
        {
          menuItemId: MENU_ITEM_ID,
          quantity: 2,
          addons: [{ addonId: ADDON_ID, name: 'Extra Cheese', price: 50 }],
        },
      ],
    },
  });

  if (!order || !order.id) {
    console.error('Failed to create order', order);
    process.exit(1);
  }

  console.log(`Order ${order.id} created successfully! Check your Kitchen App screen.`);
}

main().catch(console.error);

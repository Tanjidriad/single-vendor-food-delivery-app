/**
 * API smoke test — hits all major endpoints against a running server.
 * Run: node scripts/smoke-test.mjs
 */
const BASE = process.env.API_BASE ?? 'http://localhost:3000/api/v1';
const PASSWORD = 'Password123!';

const RESTAURANT_ID = '00000000-0000-4000-8000-000000000010'; // resolved at runtime
const MENU_ITEM_ID = '00000000-0000-4000-8000-000000000002';
const CATEGORY_ID = '00000000-0000-4000-8000-000000000001';
const ADDON_ID = '00000000-0000-4000-8000-000000000003';

const results = [];

async function req(method, path, { token, body, query, expect = [200, 201], label, formData } = {}) {
  const url = new URL(path.startsWith('http') ? path : `${BASE}${path}`);
  if (query) Object.entries(query).forEach(([k, v]) => url.searchParams.set(k, String(v)));

  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body && !formData) headers['Content-Type'] = 'application/json';

  const init = { method, headers };
  if (formData) {
    init.body = formData;
  } else if (body) {
    init.body = JSON.stringify(body);
  }

  let res;
  let data;
  try {
    res = await fetch(url, init);
    const text = await res.text();
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = text;
    }
  } catch (err) {
    results.push({ label: label ?? `${method} ${path}`, ok: false, status: 0, error: String(err) });
    return null;
  }

  const ok = expect.includes(res.status);
  results.push({
    label: label ?? `${method} ${path}`,
    ok,
    status: res.status,
    error: ok ? undefined : (data?.message ?? data?.error ?? JSON.stringify(data)?.slice(0, 120)),
  });
  return ok ? data : null;
}

async function login(creds, label) {
  const data = await req('POST', '/auth/login', {
    body: creds,
    label: `login ${label}`,
  });
  return data
    ? { accessToken: data.accessToken, refreshToken: data.refreshToken }
    : null;
}

async function main() {
  console.log(`Smoke testing ${BASE}\n`);

  // --- Public / health ---
  await req('GET', '/health', { label: 'GET /health' });

  const slugData = await req('GET', '/restaurant/slug/demo-kitchen', { label: 'GET restaurant by slug' });
  const restaurantId = slugData?.id ?? RESTAURANT_ID;

  await req('GET', `/restaurant/${restaurantId}`, { label: 'GET restaurant by id' });
  await req('GET', `/menu/restaurant/${restaurantId}`, { label: 'GET menu' });
  await req('GET', `/menu/restaurant/${restaurantId}/featured`, { label: 'GET featured menu' });
  await req('GET', `/menu/items/${MENU_ITEM_ID}`, { label: 'GET menu item' });
  await req('GET', `/menu/restaurant/${restaurantId}/banners`, { label: 'GET banners' });
  await req('GET', `/menu/restaurant/${restaurantId}/filter`, {
    query: { categoryId: CATEGORY_ID, q: 'burger' },
    label: 'GET menu filter',
  });
  await req('GET', `/menu/restaurant/${restaurantId}/search`, { query: { q: 'burger' }, label: 'GET menu search' });
  await req('GET', `/reviews/restaurant/${restaurantId}`, { label: 'GET reviews' });

  await req('POST', '/delivery-fee/quote', {
    body: {
      restaurantId,
      deliveryLat: 23.815,
      deliveryLng: 90.42,
      subtotal: 500,
    },
    label: 'POST delivery-fee quote',
  });

  await req('GET', '/delivery-fee/geocode', {
    query: { address: 'Dhaka Bangladesh' },
    label: 'GET geocode',
    expect: [200, 400, 502],
  });

  await req('GET', '/delivery-fee/reverse-geocode', {
    query: { lat: 23.81, lng: 90.41 },
    label: 'GET reverse-geocode',
    expect: [200, 400, 502],
  });

  // --- Auth ---
  const customerAuth = await login(
    { email: 'customer@example.com', password: PASSWORD },
    'customer',
  );
  const ownerAuth = await login({ email: 'owner@demokitchen.com', password: PASSWORD }, 'owner');
  const kitchenAuth = await login({ email: 'kitchen@demokitchen.com', password: PASSWORD }, 'kitchen');
  const riderAuth = await login({ phone: '+8801700000002', password: PASSWORD }, 'rider');

  const customerToken = customerAuth?.accessToken;
  const customerRefresh = customerAuth?.refreshToken;
  const ownerToken = ownerAuth?.accessToken;
  const kitchenToken = kitchenAuth?.accessToken;
  const riderToken = riderAuth?.accessToken;

  if (!customerToken || !ownerToken) {
    console.error('FATAL: Could not login — is the API running and DB seeded?');
    printReport();
    process.exit(1);
  }

  await req('POST', '/auth/otp/send', {
    body: { phone: '+8801700000003', purpose: 'VERIFY_PHONE' },
    label: 'POST otp/send (seeded customer)',
    expect: [200, 201],
  });

  await req('POST', '/auth/register', {
    body: {
      email: `smoke-${Date.now()}@test.local`,
      password: PASSWORD,
      fullName: 'Smoke Test',
    },
    label: 'POST register',
    expect: [201, 409],
  });

  // --- Users ---
  await req('GET', '/users/me', { token: customerToken, label: 'GET users/me (customer)' });
  await req('PATCH', '/users/me', {
    token: customerToken,
    body: { fullName: 'Demo Customer' },
    label: 'PATCH users/me',
  });

  if (riderToken) {
    await req('PATCH', '/users/rider/online', {
      token: riderToken,
      body: { isOnline: true },
      label: 'PATCH rider online',
    });
    await req('GET', '/users/me', { token: riderToken, label: 'GET users/me (rider)' });
  }

  // --- Devices & notifications ---
  await req('POST', '/devices/register', {
    token: customerToken,
    body: {
      deviceId: 'smoke-device-1',
      platform: 'ANDROID',
      token: 'fake-fcm-token-smoke',
    },
    label: 'POST devices/register',
  });

  const notifs = await req('GET', '/notifications', { token: customerToken, label: 'GET notifications' });
  if (notifs?.[0]?.id) {
    await req('PATCH', `/notifications/${notifs[0].id}/read`, {
      token: customerToken,
      label: 'PATCH notification read',
    });
  }

  await req('POST', '/devices/refresh-token', {
    token: customerToken,
    body: {
      deviceId: 'smoke-device-1',
      platform: 'ANDROID',
      token: 'fake-fcm-token-smoke-refreshed',
    },
    label: 'POST devices/refresh-token',
  });

  // --- Addresses & favorites ---
  const addr = await req('POST', '/addresses', {
    token: customerToken,
    body: {
      label: 'HOME',
      line1: 'Test St 1',
      city: 'Dhaka',
      latitude: 23.815,
      longitude: 90.42,
      isDefault: true,
    },
    label: 'POST address',
  });
  const addressId = addr?.id;

  await req('GET', '/addresses', { token: customerToken, label: 'GET addresses' });
  if (addressId) {
    await req('PATCH', `/addresses/${addressId}`, {
      token: customerToken,
      body: { label: 'HOME', line1: 'Test St 1 Updated', latitude: 23.815, longitude: 90.42 },
      label: 'PATCH address',
    });
  }

  await req('POST', `/favorites/${MENU_ITEM_ID}`, {
    token: customerToken,
    label: 'POST favorite',
    expect: [200, 201, 409],
  });
  await req('GET', '/favorites', { token: customerToken, label: 'GET favorites' });

  // --- Coupons ---
  await req('POST', '/coupons/validate', {
    token: customerToken,
    body: { restaurantId, code: 'WELCOME10', subtotal: 500 },
    label: 'POST coupon validate',
  });

  // --- Place order ---
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
          quantity: 1,
          addons: [{ addonId: ADDON_ID, name: 'Extra Cheese', price: 50 }],
        },
      ],
    },
    label: 'POST place order',
  });
  const orderId = order?.id;

  await req('GET', '/orders', { token: customerToken, label: 'GET orders (customer)' });
  if (orderId) {
    await req('GET', `/orders/${orderId}`, { token: customerToken, label: 'GET order by id' });
  }

  // --- Staff flow ---
  if (orderId && ownerToken) {
    await req('POST', `/orders/${orderId}/accept`, {
      token: kitchenToken ?? ownerToken,
      body: { prepMinutes: 15 },
      label: 'POST order accept',
    });

    await req('GET', '/restaurant/dashboard/stats', {
      token: ownerToken,
      label: 'GET dashboard stats',
    });

    await req('GET', '/dispatch/riders/available', {
      token: ownerToken,
      label: 'GET available riders',
    });

    const riders = await req('GET', '/dispatch/riders/available', { token: ownerToken });
    const riderProfileId = riders?.[0]?.id;

    if (riderProfileId) {
      const assignment = await req('POST', `/dispatch/orders/${orderId}/assign`, {
        token: ownerToken,
        body: { riderProfileId },
        label: 'POST assign rider',
      });
      const assignmentId = assignment?.id;

      if (assignmentId && riderToken) {
        await req('POST', `/rider/assignments/${assignmentId}/accept`, {
          token: riderToken,
          label: 'POST rider accept',
        });
      }
    } else {
      await req('POST', `/dispatch/orders/${orderId}/auto-assign`, {
        token: ownerToken,
        label: 'POST auto-assign',
        expect: [200, 201, 400],
      });
    }

    await req('PATCH', `/orders/${orderId}/status`, {
      token: kitchenToken ?? ownerToken,
      body: { status: 'PREPARING' },
      label: 'PATCH status PREPARING',
    });
    await req('PATCH', `/orders/${orderId}/status`, {
      token: kitchenToken ?? ownerToken,
      body: { status: 'READY_FOR_PICKUP' },
      label: 'PATCH status READY',
    });
    await req('PATCH', `/orders/${orderId}/status`, {
      token: riderToken ?? ownerToken,
      body: { status: 'PICKED_UP' },
      label: 'PATCH status PICKED_UP',
      expect: [200, 400, 403],
    });
    const onTheWay = await req('PATCH', `/orders/${orderId}/status`, {
      token: riderToken ?? ownerToken,
      body: { status: 'ON_THE_WAY' },
      label: 'PATCH status ON_THE_WAY',
      expect: [200, 400, 403],
    });

    const otp = onTheWay?.deliveryOtp;
    if (otp && riderToken) {
      await req('POST', `/orders/${orderId}/verify-delivery`, {
        token: riderToken,
        body: { otp },
        label: 'POST verify-delivery',
      });
    } else {
      await req('PATCH', `/orders/${orderId}/status`, {
        token: riderToken ?? ownerToken,
        body: { status: 'DELIVERED' },
        label: 'PATCH status DELIVERED',
        expect: [200, 400, 403],
      });
    }
  }

  // --- Payments (stubs) ---
  if (orderId) {
    await req('POST', `/payments/orders/${orderId}/online/initiate`, {
      token: customerToken,
      label: 'POST payment initiate',
      expect: [200, 400],
    });
    await req('POST', `/payments/orders/${orderId}/wallet`, {
      token: customerToken,
      label: 'POST wallet pay',
      expect: [200, 201, 400],
    });
  }

  // --- Reviews & complaints (need delivered order) ---
  if (orderId) {
    await req('POST', `/reviews/orders/${orderId}`, {
      token: customerToken,
      body: { rating: 5, comment: 'Great smoke test' },
      label: 'POST review',
      expect: [200, 201, 400],
    });

    const complaint = await req('POST', '/complaints', {
      token: customerToken,
      body: {
        orderId,
        type: 'COMPLAINT',
        subject: 'Smoke test complaint',
        description: 'Automated smoke test filing a complaint.',
      },
      label: 'POST complaint',
      expect: [200, 201, 400],
    });

    await req('GET', '/complaints/me', { token: customerToken, label: 'GET complaints/me' });

    if (complaint?.id && ownerToken) {
      await req('GET', '/admin/complaints', { token: ownerToken, label: 'GET admin complaints' });
      await req('PATCH', `/admin/complaints/${complaint.id}`, {
        token: ownerToken,
        body: { status: 'IN_REVIEW', staffNote: 'Reviewing' },
        label: 'PATCH admin complaint',
      });
    }
  }

  // --- Admin restaurant ---
  if (ownerToken) {
    await req('PATCH', '/admin/restaurant/profile', {
      token: ownerToken,
      body: { description: 'Demo Kitchen — smoke tested' },
      label: 'PATCH admin profile',
    });
    await req('PATCH', '/admin/restaurant/settings', {
      token: ownerToken,
      body: { defaultPrepMinutes: 20 },
      label: 'PATCH admin settings',
    });
    await req('PATCH', '/admin/restaurant/delivery-fee', {
      token: ownerToken,
      body: { baseFee: 30 },
      label: 'PATCH delivery-fee config',
    });
    await req('POST', '/admin/restaurant/operating-hours/1', {
      token: ownerToken,
      body: { openTime: '10:00', closeTime: '22:00', isClosed: false },
      label: 'POST operating hours',
    });
    await req('GET', '/admin/restaurant/banners', { token: ownerToken, label: 'GET admin banners' });
    await req('GET', '/admin/restaurant/coupons', { token: ownerToken, label: 'GET admin coupons' });
    await req('GET', '/admin/restaurant/zones', { token: ownerToken, label: 'GET admin zones' });

    await req('GET', '/reports/sales', {
      token: ownerToken,
      query: { from: '2020-01-01', to: '2030-01-01' },
      label: 'GET reports/sales',
    });
    await req('GET', '/reports/earnings', {
      token: ownerToken,
      query: { from: '2020-01-01', to: '2030-01-01' },
      label: 'GET reports/earnings',
    });
    await req('GET', '/reports/riders', { token: ownerToken, label: 'GET reports/riders' });
  }

  if (riderToken) {
    await req('GET', '/reports/rider/earnings', {
      token: riderToken,
      query: { from: '2020-01-01', to: '2030-01-01' },
      label: 'GET rider earnings',
    });
  }

  // --- Print events ---
  if (orderId && ownerToken) {
    await req('POST', '/print-events/log', {
      token: ownerToken,
      body: { orderId, printType: 'KITCHEN_TICKET', status: 'SUCCESS' },
      label: 'POST print-events/log',
    });
    await req('GET', `/print-events/orders/${orderId}`, {
      token: ownerToken,
      label: 'GET print-events',
    });
  }

  // --- Menu admin (create + delete temp category) ---
  if (ownerToken) {
    const cat = await req('POST', '/admin/menu/categories', {
      token: ownerToken,
      body: { name: 'Smoke Category', sortOrder: 99 },
      label: 'POST admin category',
    });
    if (cat?.id) {
      await req('PATCH', `/admin/menu/categories/${cat.id}`, {
        token: ownerToken,
        body: { name: 'Smoke Category Updated' },
        label: 'PATCH admin category',
      });
      await req('DELETE', `/admin/menu/categories/${cat.id}`, {
        token: ownerToken,
        label: 'DELETE admin category',
        expect: [200, 204],
      });
    }
  }

  // --- Reject order (staff) ---
  const rejectOrder = await req('POST', '/orders', {
    token: customerToken,
    body: {
      restaurantId,
      orderType: 'DELIVERY',
      paymentMethod: 'COD',
      deliveryAddress: 'Reject test',
      deliveryLat: 23.815,
      deliveryLng: 90.42,
      items: [{ menuItemId: MENU_ITEM_ID, quantity: 1 }],
    },
    label: 'POST order for reject test',
  });
  if (rejectOrder?.id) {
    await req('POST', `/orders/${rejectOrder.id}/reject`, {
      token: ownerToken,
      body: { note: 'Out of stock (smoke test)' },
      label: 'POST order reject',
    });
  }

  // --- Reorder & cancel (new order for cancel test) ---
  const order2 = await req('POST', '/orders', {
    token: customerToken,
    body: {
      restaurantId,
      orderType: 'DELIVERY',
      paymentMethod: 'COD',
      deliveryAddress: 'Cancel test',
      deliveryLat: 23.815,
      deliveryLng: 90.42,
      items: [{ menuItemId: MENU_ITEM_ID, quantity: 1 }],
    },
    label: 'POST second order (cancel test)',
  });
  if (order2?.id) {
    await req('POST', `/orders/${order2.id}/cancel`, {
      token: customerToken,
      body: { reason: 'Smoke test cancel' },
      label: 'POST cancel order',
    });
    if (orderId) {
      await req('POST', `/orders/${orderId}/reorder`, {
        token: customerToken,
        label: 'POST reorder',
        expect: [200, 201, 400],
      });
    }
  }

  // --- Cleanup favorites/address ---
  await req('DELETE', `/favorites/${MENU_ITEM_ID}`, {
    token: customerToken,
    label: 'DELETE favorite',
    expect: [200, 204, 404],
  });
  if (addressId) {
    await req('DELETE', `/addresses/${addressId}`, {
      token: customerToken,
      label: 'DELETE address',
      expect: [200, 204],
    });
  }

  if (customerToken && customerRefresh) {
    await req('POST', '/auth/logout', {
      token: customerToken,
      body: { refreshToken: customerRefresh },
      label: 'POST logout',
      expect: [200, 201, 204],
    });
  }

  await req('POST', '/auth/refresh', {
    body: { refreshToken: customerRefresh ?? 'invalid' },
    label: 'POST refresh (may fail after logout)',
    expect: [200, 201, 401],
  });

  printReport();
  const failed = results.filter((r) => !r.ok).length;
  process.exit(failed > 0 ? 1 : 0);
}

function printReport() {
  const passed = results.filter((r) => r.ok).length;
  const failed = results.filter((r) => !r.ok);
  console.log('\n--- Results ---');
  console.log(`Passed: ${passed}/${results.length}`);
  if (failed.length) {
    console.log('\nFailed:');
    for (const f of failed) {
      console.log(`  [${f.status}] ${f.label}: ${f.error ?? 'unknown'}`);
    }
  } else {
    console.log('All checks passed.');
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

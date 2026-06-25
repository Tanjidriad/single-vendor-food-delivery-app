/**
 * E2E test: dispatchExternal with Pathao auto-creation
 * -----------------------------------------------------
 * 1. Logs in as kitchen staff
 * 2. Finds the most recent accepted/preparing/ready order
 * 3. Calls POST /orders/:id/dispatch-external without a trackingId
 * 4. Expects the response to contain a real Pathao consignment_id
 *
 * Run: node test_pathao_e2e.js
 */

const BASE = 'http://localhost:3000/api/v1';

// ── adjust these to a real kitchen user in your local DB ──────────────────────
const KITCHEN_EMAIL    = 'owner@demokitchen.com';
const KITCHEN_PASSWORD = 'Password123!';
// ─────────────────────────────────────────────────────────────────────────────

async function post(path, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = { raw: text }; }
  return { status: res.status, ok: res.ok, json };
}

async function get(path, token) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const text = await res.text();
  let json; try { json = JSON.parse(text); } catch { json = { raw: text }; }
  return { status: res.status, ok: res.ok, json };
}

function separator(t) {
  console.log('\n' + '─'.repeat(60));
  console.log('  ' + t);
  console.log('─'.repeat(60));
}

(async () => {
  separator('STEP 1 – Login as kitchen staff');
  const loginRes = await post('/auth/login', { email: KITCHEN_EMAIL, password: KITCHEN_PASSWORD });
  console.log('Status:', loginRes.status);
  if (!loginRes.ok) {
    console.error('Login failed:', loginRes.json);
    process.exit(1);
  }
  const token = loginRes.json?.data?.accessToken ?? loginRes.json?.accessToken;
  console.log('✅ Logged in, token:', token?.slice(0, 30) + '…');

  separator('STEP 2 – Find a dispatchable order');
  const listRes = await get('/orders?limit=50', token);
  if (!listRes.ok) { console.error('List failed:', listRes.json); process.exit(1); }

  const orders = Array.isArray(listRes.json)
    ? listRes.json
    : listRes.json?.data ?? listRes.json?.orders ?? [];

  const dispatchable = orders.find(o =>
    ['ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP'].includes(o.status)
  );

  if (!dispatchable) {
    console.error('❌ No dispatchable orders found. Place and accept an order first.');
    console.log('Found statuses:', orders.slice(0, 5).map(o => o.status));
    process.exit(1);
  }
  console.log(`✅ Using order: ${dispatchable.orderNumber} (${dispatchable.status}) id=${dispatchable.id}`);

  separator('STEP 3 – Dispatch via Pathao (no manual trackingId)');
  const dispatchRes = await post(`/orders/${dispatchable.id}/dispatch-external`, {
    deliveryService: 'Pathao Parcel',
    // intentionally omitting trackingId → backend should auto-create
  }, token);

  console.log('Status:', dispatchRes.status);
  console.log(JSON.stringify(dispatchRes.json, null, 2));

  if (!dispatchRes.ok) {
    console.error('❌ Dispatch failed');
    process.exit(1);
  }

  const trackingId = dispatchRes.json?.trackingId;
  if (!trackingId) {
    console.error('❌ Response is missing trackingId — Pathao auto-create may have failed');
    process.exit(1);
  }

  separator('✅  ALL STEPS PASSED');
  console.log(`  Order status:    ${dispatchRes.json?.status}`);
  console.log(`  Tracking ID:     ${trackingId}`);
  console.log(`  Tracking URL:    ${dispatchRes.json?.trackingUrl ?? '—'}`);
  console.log(`  Delivery svc:    ${dispatchRes.json?.deliveryService}`);
  console.log();
})();

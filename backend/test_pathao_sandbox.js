/**
 * Pathao Courier Sandbox – Step-by-step API Test
 * -----------------------------------------------
 * Run with:  node test_pathao_sandbox.js
 *
 * Steps:
 *   1) Issue an access token (grant_type: password)
 *   2) List your sandbox stores   → grab the first store_id
 *   3) Create a dummy parcel order → print consignment_id (tracking ID)
 */

const BASE_URL = 'https://courier-api-sandbox.pathao.com';

const CREDENTIALS = {
  client_id:     '7N1aMJQbWm',
  client_secret: 'wRcaibZkUdSNz2EI9ZyuXLlNrnAv0TdPUPXMnD39',
  username:      'test@pathao.com',
  password:      'lovePathao',
  grant_type:    'password',
};

// ── helpers ──────────────────────────────────────────────────────────────────

function separator(title) {
  console.log('\n' + '─'.repeat(60));
  console.log(`  ${title}`);
  console.log('─'.repeat(60));
}

async function post(path, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });

  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = { raw: text }; }

  return { status: res.status, ok: res.ok, json };
}

async function get(path, token) {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = { raw: text }; }

  return { status: res.status, ok: res.ok, json };
}

// ── Step 1: Get access token ──────────────────────────────────────────────────

async function getToken() {
  separator('STEP 1 – Issue Access Token');
  console.log('POST', `${BASE_URL}/aladdin/api/v1/issue-token`);

  const { status, ok, json } = await post('/aladdin/api/v1/issue-token', CREDENTIALS);

  console.log(`Status: ${status}`);
  console.log(JSON.stringify(json, null, 2));

  if (!ok || !json.access_token) {
    throw new Error(`❌ Token request failed (HTTP ${status})`);
  }

  console.log(`\n✅ access_token obtained (expires_in: ${json.expires_in}s)`);
  return json.access_token;
}

// ── Step 2: List stores ───────────────────────────────────────────────────────

async function getStores(token) {
  separator('STEP 2 – List Sandbox Stores');
  console.log('GET', `${BASE_URL}/aladdin/api/v1/stores`);

  const { status, ok, json } = await get('/aladdin/api/v1/stores', token);

  console.log(`Status: ${status}`);
  console.log(JSON.stringify(json, null, 2));

  if (!ok) {
    throw new Error(`❌ Store list request failed (HTTP ${status})`);
  }

  // The API returns { data: { data: [...stores] } } or similar shapes
  const stores =
    json?.data?.data ??
    json?.data ??
    (Array.isArray(json) ? json : []);

  if (!stores.length) {
    throw new Error('❌ No stores found in sandbox account');
  }

  const first = stores[0];
  console.log(`\n✅ Found ${stores.length} store(s). Using store_id: ${first.store_id ?? first.id}`);
  return first.store_id ?? first.id;
}

// ── Step 3: Create a test order ───────────────────────────────────────────────

async function createOrder(token, storeId) {
  separator('STEP 3 – Create Test Parcel Order');
  console.log('POST', `${BASE_URL}/aladdin/api/v1/orders`);

  const payload = {
    store_id:            storeId,
    merchant_order_id:   `TEST-${Date.now()}`,   // your internal order ref
    recipient_name:      'Test Customer',
    recipient_phone:     '01700000000',
    recipient_address:   'Uttara, Sector-7, Dhaka',
    delivery_type:       48,                      // 48 = normal delivery
    item_type:           2,                       // 2 = food/parcel
    special_instruction: 'Sandbox test order – please ignore',
    item_quantity:       1,
    item_weight:         '0.5',
    item_description:    'Food delivery test item',
    amount_to_collect:   0,                       // 0 = prepaid / no COD
  };

  console.log('\nRequest body:');
  console.log(JSON.stringify(payload, null, 2));

  const { status, ok, json } = await post('/aladdin/api/v1/orders', payload, token);

  console.log(`\nStatus: ${status}`);
  console.log(JSON.stringify(json, null, 2));

  if (!ok) {
    throw new Error(`❌ Order creation failed (HTTP ${status})`);
  }

  const consignmentId =
    json?.data?.consignment_id ??
    json?.consignment_id ??
    '(not found in response)';

  console.log(`\n✅ Order created!  consignment_id (tracking ID): ${consignmentId}`);
  return consignmentId;
}

// ── main ──────────────────────────────────────────────────────────────────────

(async () => {
  console.log('🚀 Pathao Courier Sandbox – API Smoke Test');
  console.log(`   Base URL: ${BASE_URL}`);

  try {
    const token       = await getToken();
    const storeId     = await getStores(token);
    const trackingId  = await createOrder(token, storeId);

    separator('✅  ALL STEPS PASSED');
    console.log(`  Tracking ID: ${trackingId}`);
    console.log('  The sandbox integration is working correctly.\n');
  } catch (err) {
    separator('❌  TEST FAILED');
    console.error(' ', err.message, '\n');
    process.exit(1);
  }
})();

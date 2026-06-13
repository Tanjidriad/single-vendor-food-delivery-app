import fetch from 'node-fetch';

const BASE = process.env.API_BASE ?? 'http://localhost:3000/api/v1';
const PASSWORD = 'Password123!';

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

async function main() {
  const ownerToken = await req('POST', '/auth/login', { body: { email: 'owner@demokitchen.com', password: PASSWORD } });
  
  // Hardcoded to auto-assign the exact order ID we found
  const orderId = '6ae340fc-86fe-44c2-9035-c9742137bec8';
  
  console.log(`Dispatching order ${orderId} to an available rider...`);
  const assignResult = await req('POST', `/dispatch/orders/${orderId}/auto-assign`, {
    token: ownerToken.accessToken,
  });
  
  console.log(assignResult);
}

main().catch(console.error);

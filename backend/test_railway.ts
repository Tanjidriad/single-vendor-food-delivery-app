const BASE_URL = 'https://single-vendor-food-delivery-app-production.up.railway.app/api/v1';

async function main() {
  try {
    const loginRes = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'owner@demokitchen.com', password: 'Password123!' })
    });
    const loginData = await loginRes.json();
    if (!loginRes.ok) throw new Error(loginData.message || 'Login failed');
    
    const token = loginData.accessToken;
    console.log('Logged in user:', loginData.user);

    const ordersRes = await fetch(`${BASE_URL}/orders?limit=10`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const ordersData = await ordersRes.json();
    if (!ordersRes.ok) throw new Error(ordersData.message || 'Fetch orders failed');
    
    console.log(`Fetched ${ordersData.length} orders.`);
    if (ordersData.length > 0) {
      console.log('Latest 2 orders:', JSON.stringify(ordersData.slice(0, 2), null, 2));
    }
  } catch (err: any) {
    console.error('Error:', err.message);
  }
}
main();

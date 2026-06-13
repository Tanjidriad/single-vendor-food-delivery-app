async function run() {
  // 1. Login as customer
  const res = await fetch("http://localhost:3000/api/v1/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: "customer@example.com",
      password: "Password123!"
    })
  });
  const data = await res.json();
  const token = data.accessToken;
  
  // 2. Create order
  const orderRes = await fetch("http://localhost:3000/api/v1/orders", {
    method: "POST",
    headers: { 
      "Content-Type": "application/json",
      "Authorization": "Bearer " + token
    },
    body: JSON.stringify({
      restaurantId: "46c52268-2146-4543-ab10-92dd34e53d3a", // Demo restaurant
      orderType: "DELIVERY",
      paymentMethod: "COD",
      items: [
        { menuItemId: "0b15b3a4-8463-4de7-9e4a-b5e1a1cd40a9", quantity: 1 }
      ],
      deliveryAddress: "123 Test St",
      deliveryLat: 40,
      deliveryLng: -74
    })
  });
  const orderData = await orderRes.json();
  console.log("Order created:", orderData);
}
run();

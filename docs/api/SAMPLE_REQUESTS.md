# Sample API Requests

> Full endpoint reference: [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)

## Login (customer)

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "customer@example.com",
  "password": "Password123!"
}
```

## Delivery fee quote

```http
POST /api/v1/delivery-fee/quote
Content-Type: application/json

{
  "restaurantId": "<restaurant-uuid-from-seed>",
  "deliveryLat": 23.815,
  "deliveryLng": 90.420,
  "subtotal": 500
}
```

## Place order

```http
POST /api/v1/orders
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "restaurantId": "<restaurant-uuid>",
  "orderType": "DELIVERY",
  "paymentMethod": "COD",
  "deliveryAddress": "House 12, Road 5, Dhaka",
  "deliveryLat": 23.815,
  "deliveryLng": 90.420,
  "items": [
    {
      "menuItemId": "<burger-uuid>",
      "quantity": 2,
      "notes": "No onion",
      "addons": [
        { "addonId": "<cheese-addon-uuid>", "name": "Extra Cheese", "price": 50 }
      ]
    }
  ]
}
```

## Assign rider (staff)

```http
POST /api/v1/dispatch/orders/<orderId>/assign
Authorization: Bearer <staff-accessToken>
Content-Type: application/json

{
  "riderProfileId": "<rider-profile-uuid>"
}
```

## List available riders (staff)

```http
GET /api/v1/dispatch/riders/available
Authorization: Bearer <staff-accessToken>
```

## Update profile

```http
PATCH /api/v1/users/me
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "fullName": "Jane Customer"
}
```

## Cancel order (customer)

```http
POST /api/v1/orders/<orderId>/cancel
Authorization: Bearer <customer-accessToken>
Content-Type: application/json

{
  "reason": "Changed my mind"
}
```

## Verify delivery OTP (rider)

```http
POST /api/v1/orders/<orderId>/verify-delivery
Authorization: Bearer <rider-accessToken>
Content-Type: application/json

{
  "otp": "123456"
}
```

## File complaint / refund request

```http
POST /api/v1/complaints
Authorization: Bearer <customer-accessToken>
Content-Type: application/json

{
  "orderId": "<order-uuid>",
  "type": "REFUND_REQUEST",
  "subject": "Wrong items",
  "description": "Received salad instead of burger.",
  "refundAmount": 450
}
```

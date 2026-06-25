import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/features/orders/data/models/order_model.dart';

void main() {
  test('parses fields and tolerates loose JSON types', () {
    final order = OrderModel.fromJson({
      'id': 1, // non-string id is coerced
      'orderNumber': 'A100',
      'status': 'ACCEPTED',
      'grandTotal': '15.5', // string number is coerced
      'createdAt': '2024-01-01T00:00:00.000Z',
    });

    expect(order.id, '1');
    expect(order.orderNumber, 'A100');
    expect(order.status, 'ACCEPTED');
    expect(order.grandTotal, 15.5);
    expect(order.createdAt, isNotNull);
    expect(order.isActive, isTrue);
    expect(order.raw['orderNumber'], 'A100');
  });

  test('terminal statuses are not active', () {
    expect(
      OrderModel.fromJson({'id': 'x', 'status': 'DELIVERED'}).isActive,
      isFalse,
    );
    expect(
      OrderModel.fromJson({'id': 'x', 'status': 'CANCELLED'}).isActive,
      isFalse,
    );
  });

  test('applies defaults when fields are absent', () {
    final order = OrderModel.fromJson({'id': 'x'});

    expect(order.status, 'PLACED');
    expect(order.grandTotal, 0);
    expect(order.createdAt, isNull);
    expect(order.subtotal, isNull);
  });
}

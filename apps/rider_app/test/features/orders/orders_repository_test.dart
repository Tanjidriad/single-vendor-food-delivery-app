import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rider_app/core/errors/failures.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/network/api_endpoints.dart';
import 'package:rider_app/features/orders/data/orders_repository.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response _ok(Object? data) =>
    Response(requestOptions: RequestOptions(path: '/x'), statusCode: 200, data: data);

void main() {
  late _MockApiClient api;
  late OrdersRepository repo;

  setUp(() {
    api = _MockApiClient();
    repo = OrdersRepository(api);
  });

  test('getOrder returns the order map', () async {
    when(() => api.get(any())).thenAnswer((_) async => _ok({'id': 'o1'}));

    final order = await repo.getOrder('o1');

    expect(order['id'], 'o1');
  });

  test('getOrder maps a DioException to a typed Failure', () async {
    when(() => api.get(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(repo.getOrder('o1'), throwsA(isA<NetworkFailure>()));
  });

  test('getOrder throws a ServerFailure when the body is not a map', () async {
    when(() => api.get(any())).thenAnswer((_) async => _ok('unexpected'));

    expect(repo.getOrder('o1'), throwsA(isA<ServerFailure>()));
  });

  test('listOrders returns the payload list', () async {
    when(() => api.get(
          ApiEndpoints.orders,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _ok([
          {'id': 'a'},
          {'id': 'b'},
        ]));

    final orders = await repo.listOrders();

    expect(orders, hasLength(2));
  });

  test('listOrders tolerates a non-list body', () async {
    when(() => api.get(
          ApiEndpoints.orders,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _ok(null));

    expect(await repo.listOrders(), isEmpty);
  });

  test('fetchPendingAssignments swallows errors and returns empty', () async {
    when(() => api.get(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(await repo.fetchPendingAssignments(), isEmpty);
  });
}

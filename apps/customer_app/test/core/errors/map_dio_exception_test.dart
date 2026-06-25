import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/core/errors/failures.dart';
import 'package:customer_app/core/errors/map_dio_exception.dart';

void main() {
  final req = RequestOptions(path: '/x');

  test('connection timeout maps to NetworkFailure', () {
    final failure = mapDioException(
      DioException(requestOptions: req, type: DioExceptionType.connectionTimeout),
    );
    expect(failure, isA<NetworkFailure>());
  });

  test('connection error maps to NetworkFailure', () {
    final failure = mapDioException(
      DioException(requestOptions: req, type: DioExceptionType.connectionError),
    );
    expect(failure, isA<NetworkFailure>());
  });

  test('401 maps to AuthFailure carrying the server message', () {
    final failure = mapDioException(
      DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: req,
          statusCode: 401,
          data: {'message': 'Token expired'},
        ),
      ),
    );
    expect(failure, isA<AuthFailure>());
    expect(failure.message, 'Token expired');
  });

  test('500 maps to ServerFailure carrying the server error field', () {
    final failure = mapDioException(
      DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: req,
          statusCode: 500,
          data: {'error': 'Internal boom'},
        ),
      ),
    );
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Internal boom');
  });

  test('list-style validation messages use the first entry', () {
    final failure = mapDioException(
      DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: req,
          statusCode: 400,
          data: {'message': ['phone must be valid', 'name required']},
        ),
      ),
    );
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'phone must be valid');
  });

  test('badResponse without a parseable body falls back to a default message', () {
    final failure = mapDioException(
      DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: req, statusCode: 503, data: 'plain'),
      ),
    );
    expect(failure, isA<ServerFailure>());
    expect(failure.message, isNotEmpty);
  });

  test('Failure.toString surfaces the human message', () {
    expect(const ServerFailure('oops').toString(), 'oops');
  });
}

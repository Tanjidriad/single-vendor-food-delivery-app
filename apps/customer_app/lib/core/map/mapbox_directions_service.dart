import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/app_map_route_point.dart';

/// Fetches driving routes from the Mapbox Directions API.
class MapboxDirectionsService {
  MapboxDirectionsService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _baseUrl =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  static String get _accessToken {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is not set. Add it to apps/customer_app/.env '
        '(copy from .env.example)',
      );
    }
    return token;
  }

  Future<List<AppMapRoutePoint>> getRoute(
    AppMapRoutePoint start,
    AppMapRoutePoint end,
  ) {
    return getRouteThrough([start, end]);
  }

  /// Driving route through ordered waypoints (2 or more).
  Future<List<AppMapRoutePoint>> getRouteThrough(
    List<AppMapRoutePoint> waypoints,
  ) async {
    if (waypoints.length < 2) return [];

    try {
      final coordPath = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final url =
          '$_baseUrl/$coordPath?geometries=geojson&overview=full&access_token=$_accessToken';

      final response = await _dio.get<Map<String, dynamic>>(url);

      final routes = response.data?['routes'];
      if (response.statusCode != 200 || routes is! List || routes.isEmpty) {
        return _straightLineFallback(waypoints);
      }

      final geometry = routes.first['geometry'];
      if (geometry is! Map || geometry['type'] != 'LineString') {
        return _straightLineFallback(waypoints);
      }

      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.isEmpty) {
        return _straightLineFallback(waypoints);
      }

      return coordinates.map((coord) {
        final pair = coord as List;
        return AppMapRoutePoint(
          latitude: (pair[1] as num).toDouble(),
          longitude: (pair[0] as num).toDouble(),
        );
      }).toList();
    } catch (e, st) {
      debugPrint('Mapbox directions error: $e\n$st');
      return _straightLineFallback(waypoints);
    }
  }

  List<AppMapRoutePoint> _straightLineFallback(List<AppMapRoutePoint> waypoints) {
    return List<AppMapRoutePoint>.from(waypoints);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxDirectionsService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox/driving';
  static String get _accessToken {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is not set. Add it to apps/rider_app/.env '
        '(copy from .env.example)',
      );
    }
    return token;
  }

  Future<List<Position>> getRoute(Position start, Position end) async {
    try {
      final url =
          '$_baseUrl/${start.lng},${start.lat};${end.lng},${end.lat}?geometries=geojson&access_token=$_accessToken';
      
      debugPrint('Fetching Mapbox route: $url');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        final route = response.data['routes'][0];
        final geometry = route['geometry'];
        
        if (geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;
          debugPrint('Mapbox returned ${coordinates.length} points for route');
          return coordinates.map((coord) {
            return Position(coord[0] as num, coord[1] as num);
          }).toList();
        }
      } else {
         debugPrint('Mapbox routing failed: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      debugPrint('Error fetching Mapbox route: $e');
    }
    return [];
  }
}

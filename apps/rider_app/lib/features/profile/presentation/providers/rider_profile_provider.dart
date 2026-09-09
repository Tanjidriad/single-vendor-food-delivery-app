import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/rider_profile.dart';

/// Fetches the caller's own rider profile (identity, work details, documents,
/// approval status) from `GET /rider/profile`.
final riderProfileProvider = FutureProvider<RiderProfileView>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiEndpoints.riderProfile);
  final raw = res.data;
  if (raw is! Map) {
    throw Exception('Unexpected profile response');
  }
  return RiderProfileView.fromJson(Map<String, dynamic>.from(raw));
});

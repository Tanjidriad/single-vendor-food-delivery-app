import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/rider_profile.dart';

/// Fetches the caller's own rider profile (identity, work details, documents,
/// approval status) from `GET /rider/profile`.
///
/// A [FutureProvider] so the screen gets loading/error/data for free and can
/// refresh by invalidating the provider after an edit/upload.
final riderProfileProvider = FutureProvider<RiderProfileView>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get(ApiEndpoints.riderProfile);
  return RiderProfileView.fromJson(Map<String, dynamic>.from(res.data as Map));
});

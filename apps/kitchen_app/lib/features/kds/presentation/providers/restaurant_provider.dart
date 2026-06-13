import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/providers/auth_provider.dart';

class RestaurantProfile {
  final String id;
  final String name;
  final bool isActive;
  final String? logoUrl;

  const RestaurantProfile({
    required this.id,
    required this.name,
    required this.isActive,
    this.logoUrl,
  });

  factory RestaurantProfile.fromJson(Map<String, dynamic> json) {
    return RestaurantProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Kitchen',
      isActive: json['isActive'] == true || json['isOpen'] == true,
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}

class RestaurantState {
  final RestaurantProfile? profile;
  final bool isLoading;
  final String? error;

  const RestaurantState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  String get displayName => profile?.name ?? 'Kitchen';
  String? get restaurantId => profile?.id;
}

final restaurantProvider = AsyncNotifierProvider<RestaurantNotifier, RestaurantState>(() {
  return RestaurantNotifier();
});

class RestaurantNotifier extends AsyncNotifier<RestaurantState> {
  ApiClient get _apiClient => ref.read(apiClientProvider);

  @override
  Future<RestaurantState> build() async {
    final authUser = ref.watch(authProvider.select((s) => s.user));
    final id = _extractRestaurantId(authUser);

    if (id == null || id.isEmpty) {
      return const RestaurantState(
        error: 'Restaurant not assigned to this account.',
      );
    }

    return _fetchProfile(id);
  }

  String? _extractRestaurantId(Map<String, dynamic>? user) {
    if (user == null) return null;

    // Try common shapes from the backend user payload.
    final candidates = [
      user['restaurantId'],
      user['restaurant']?['id'],
      user['restaurantId']?['id'],
    ];

    for (final value in candidates) {
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    // Debug-only fallback from build config.
    if (kDebugMode && AppConfig.restaurantId.isNotEmpty) {
      return AppConfig.restaurantId;
    }

    return null;
  }

  Future<RestaurantState> _fetchProfile(String id) async {
    try {
      final response = await _apiClient.get('/restaurant/$id');
      final profile = RestaurantProfile.fromJson(response.data as Map<String, dynamic>);
      return RestaurantState(profile: profile);
    } catch (e) {
      // If the profile endpoint fails, at least show the ID-derived fallback
      // so the kitchen can keep operating while the issue is fixed.
      return RestaurantState(
        profile: RestaurantProfile(id: id, name: 'Kitchen', isActive: true),
        error: 'Could not load restaurant profile.',
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authUser = ref.read(authProvider).user;
      final id = _extractRestaurantId(authUser);
      if (id == null || id.isEmpty) {
        return const RestaurantState(error: 'Restaurant not assigned.');
      }
      return _fetchProfile(id);
    });
  }
}

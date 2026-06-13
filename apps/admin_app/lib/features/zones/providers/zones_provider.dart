import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class Zone {
  final String id;
  final String name;
  final double? maxDistanceKm;
  final Map<String, dynamic>? polygonGeo;
  final bool isActive;

  Zone({
    required this.id,
    required this.name,
    this.maxDistanceKm,
    this.polygonGeo,
    required this.isActive,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'],
      name: json['name'],
      maxDistanceKm: json['maxDistanceKm']?.toDouble(),
      polygonGeo: json['polygonGeo'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class ZonesState {
  final List<Zone> zones;
  final bool isLoading;
  final String? error;

  ZonesState({
    this.zones = const [],
    this.isLoading = false,
    this.error,
  });

  ZonesState copyWith({
    List<Zone>? zones,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ZonesState(
      zones: zones ?? this.zones,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ZonesNotifier extends Notifier<ZonesState> {
  @override
  ZonesState build() {
    // Initial state
    state = ZonesState();
    // Kick off fetch immediately, but without awaiting so build can return
    Future.microtask(() => fetchZones());
    return state;
  }

  Future<void> fetchZones() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/admin/restaurant/zones');
      final List<dynamic> data = res.data['data'] ?? res.data;
      final zones = data.map((z) => Zone.fromJson(z)).toList();
      state = state.copyWith(zones: zones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createZone(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/admin/restaurant/zones', data: data);
      await fetchZones();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateZone(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/admin/restaurant/zones/$id', data: data);
      await fetchZones();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteZone(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/admin/restaurant/zones/$id');
      await fetchZones();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleZoneActive(String id, bool isActive) async {
    await updateZone(id, {'isActive': isActive});
  }
}

final zonesProvider = NotifierProvider<ZonesNotifier, ZonesState>(() {
  return ZonesNotifier();
});

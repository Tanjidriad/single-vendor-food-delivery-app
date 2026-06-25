import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../../data/orders_repository.dart';
import '../utils/tracking_map_markers.dart';

/// Live order + rider location for the tracking screen.
class OrderTrackingState {
  const OrderTrackingState({
    this.order,
    this.riderLocation,
    this.isLoading = false,
    this.error,
  });

  final Map<String, dynamic>? order;
  final Map<String, dynamic>? riderLocation;
  final bool isLoading;
  final Object? error;

  OrderTrackingState copyWith({
    Map<String, dynamic>? order,
    Map<String, dynamic>? riderLocation,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return OrderTrackingState(
      order: order ?? this.order,
      riderLocation: riderLocation ?? this.riderLocation,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Rider card data derived from [order] JSON.
class OrderRiderInfo {
  const OrderRiderInfo({
    required this.isAssigned,
    required this.title,
    required this.subtitle,
    this.name,
    this.phone,
  });

  final bool isAssigned;
  final String title;
  final String subtitle;
  final String? name;
  final String? phone;
}

OrderRiderInfo riderInfoFromOrder(Map<String, dynamic> order) {
  final assignment = order['assignment'];
  if (assignment is! Map<String, dynamic>) {
    return const OrderRiderInfo(
      isAssigned: false,
      title: 'Waiting for rider...',
      subtitle: 'Assigning nearby rider',
    );
  }

  final status = assignment['status'] as String?;
  if (status == 'EXPIRED' || status == 'REJECTED') {
    return const OrderRiderInfo(
      isAssigned: false,
      title: 'Waiting for rider...',
      subtitle: 'Assigning nearby rider',
    );
  }

  final rider = assignment['rider'];
  if (rider is! Map<String, dynamic>) {
    return const OrderRiderInfo(
      isAssigned: false,
      title: 'Waiting for rider...',
      subtitle: 'Assigning nearby rider',
    );
  }

  final name = rider['fullName'] as String? ?? 'Your rider';
  final user = rider['user'];
  final phone = user is Map<String, dynamic> ? user['phone'] as String? : null;
  final vehicle = rider['vehicleType'] as String?;

  final subtitle = status == 'NOTIFIED'
      ? 'Assigned — accepting delivery'
      : (vehicle != null && vehicle.isNotEmpty ? vehicle : 'On the way to you');

  return OrderRiderInfo(
    isAssigned: true,
    title: name,
    subtitle: subtitle,
    name: name,
    phone: phone,
  );
}

double orderGrandTotal(Map<String, dynamic> order) {
  return (order['grandTotal'] as num?)?.toDouble() ??
      (order['totalAmount'] as num?)?.toDouble() ??
      0;
}

double orderItemLineTotal(Map<String, dynamic> item) {
  final fromLine = (item['lineTotal'] as num?)?.toDouble();
  if (fromLine != null) return fromLine;
  final unit = (item['unitPrice'] as num?)?.toDouble() ?? 0;
  final qty = (item['quantity'] as num?)?.toInt() ?? 1;
  return unit * qty;
}

double? _coordFromJson(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Last known rider position from GET /orders/:id (assignment.rider.locations).
Map<String, dynamic>? riderLocationFromOrder(Map<String, dynamic> order) {
  final assignment = order['assignment'];
  if (assignment is! Map<String, dynamic>) return null;

  final rider = assignment['rider'];
  if (rider is! Map<String, dynamic>) return null;

  final locations = rider['locations'];
  if (locations is! List || locations.isEmpty) return null;

  final latest = locations.first;
  if (latest is! Map<String, dynamic>) return null;

  final lat = _coordFromJson(latest['latitude']);
  final lng = _coordFromJson(latest['longitude']);
  if (lat == null || lng == null) return null;

  return {
    'latitude': lat,
    'longitude': lng,
    if (latest['heading'] != null) 'heading': latest['heading'],
    if (latest['recordedAt'] != null) 'recordedAt': latest['recordedAt'],
  };
}

/// Streams order updates via REST (initial + refresh) and socket events.
final orderTrackingProvider = StreamProvider.autoDispose
    .family<OrderTrackingState, String>((ref, orderId) {
  final repo = ref.watch(ordersRepositoryProvider);
  final socket = ref.read(socketServiceProvider);
  final token = ref.read(authTokenProvider);

  final controller = StreamController<OrderTrackingState>();
  var current = const OrderTrackingState(isLoading: true);
  Timer? pollTimer;

  void emit(OrderTrackingState next) {
    current = next;
    if (!controller.isClosed) {
      controller.add(next);
    }
  }

  Future<Map<String, dynamic>> enrichOrder(Map<String, dynamic> order) async {
    final restaurant = order['restaurant'];
    if (restaurant is Map) {
      final map = Map<String, dynamic>.from(restaurant);
      if (coordFromJson(map['latitude']) != null &&
          coordFromJson(map['longitude']) != null) {
        return order;
      }
    }

    final restaurantId = order['restaurantId'] as String?;
    if (restaurantId == null || restaurantId.isEmpty) return order;

    try {
      final details =
          await ref.read(restaurantRepositoryProvider).getById(restaurantId);
      return {...order, 'restaurant': details};
    } catch (_) {
      return order;
    }
  }

  Future<void> refreshOrder() async {
    try {
      var order = (await repo.getOrder(orderId)).raw;
      order = await enrichOrder(order);
      final initialRider = estimatedRiderLocation(
        order,
        riderLocationFromOrder(order),
      );
      final oldStatus = current.order?['status'];
      final newStatus = order['status'];

      if (oldStatus != null && newStatus != null && oldStatus != newStatus) {
        // Status changed, alert the user
        try {
          unawaited(HapticFeedback.mediumImpact());
          unawaited(SystemSound.play(SystemSoundType.alert));
        } catch (_) {}
      }

      emit(
        current.copyWith(
          order: order,
          riderLocation: initialRider ?? current.riderLocation,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isLoading: current.order == null,
          error: e,
        ),
      );
    }
  }

  void onRealtimeEvent(Map<String, dynamic> data) {
    final eventOrderId = data['orderId'] as String?;
    if (eventOrderId != null && eventOrderId != orderId) return;
    unawaited(refreshOrder());
  }

  void onRiderLocation(Map<String, dynamic> data) {
    final lat = coordFromJson(data['latitude']);
    final lng = coordFromJson(data['longitude']);
    if (lat == null || lng == null) return;
    emit(current.copyWith(riderLocation: data));
  }

  void setupRealtime() {
    if (token == null || token.isEmpty) return;

    socket.connect(token);
    socket.joinOrder(orderId);
    socket.onOrderStatus(onRealtimeEvent);
    socket.onAssignmentAccepted(onRealtimeEvent);
    socket.onAssignmentCreated(onRealtimeEvent);
    socket.onRiderLocation(onRiderLocation);

    pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(refreshOrder()),
    );
  }

  unawaited(refreshOrder());
  setupRealtime();

  ref.onDispose(() {
    pollTimer?.cancel();
    socket.removeOrderTrackingListeners();
    controller.close();
  });

  return controller.stream;
});

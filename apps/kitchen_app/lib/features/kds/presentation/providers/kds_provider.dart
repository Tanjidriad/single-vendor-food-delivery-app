import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../../../core/services/order_alert_service.dart';
import '../../../../core/services/print_service.dart';
import '../../domain/order_workflow.dart';

final kdsProvider = NotifierProvider<KdsNotifier, KdsState>(() {
  return KdsNotifier();
});

final kdsNewOrdersProvider = Provider<List<dynamic>>((ref) {
  final orders = ref.watch(kdsProvider).orders;
  return orders
      .where(
        (o) =>
            OrderWorkflowMapper.getSection(
              OrderWorkflowMapper.getCanonicalStatus(o),
            ) ==
            KitchenSection.newOrders,
      )
      .toList();
});

final kdsPreparingOrdersProvider = Provider<List<dynamic>>((ref) {
  final orders = ref.watch(kdsProvider).orders;
  return orders
      .where(
        (o) =>
            OrderWorkflowMapper.getSection(
              OrderWorkflowMapper.getCanonicalStatus(o),
            ) ==
            KitchenSection.preparing,
      )
      .toList();
});

final kdsReadyOrdersProvider = Provider<List<dynamic>>((ref) {
  final orders = ref.watch(kdsProvider).orders;
  return orders
      .where(
        (o) =>
            OrderWorkflowMapper.getSection(
              OrderWorkflowMapper.getCanonicalStatus(o),
            ) ==
            KitchenSection.ready,
      )
      .toList();
});

final kdsReturnedOrdersProvider = Provider<List<dynamic>>((ref) {
  final orders = ref.watch(kdsProvider).orders;
  return orders
      .where(
        (o) =>
            OrderWorkflowMapper.getSection(
              OrderWorkflowMapper.getCanonicalStatus(o),
            ) ==
            KitchenSection.returned,
      )
      .toList();
});

/// A StreamProvider that yields socket events so the UI can listen reactively.
final kdsEventStreamProvider = StreamProvider.autoDispose<Map<String, dynamic>>(
  (ref) {
    return ref.watch(kdsProvider.notifier).eventStream;
  },
);

class KdsState {
  final List<dynamic> orders;
  final bool isLoading;
  final bool isConnected;
  final bool isRestaurantActive;
  final DateTime? lastSuccessfulFetchAt;

  KdsState({
    this.orders = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.isRestaurantActive = true,
    this.lastSuccessfulFetchAt,
  });

  /// Socket connected, or a recent REST poll succeeded (orders still flow).
  bool get networkHealthy {
    if (isConnected) return true;
    final last = lastSuccessfulFetchAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < const Duration(seconds: 30);
  }

  KdsState copyWith({
    List<dynamic>? orders,
    bool? isLoading,
    bool? isConnected,
    bool? isRestaurantActive,
    DateTime? lastSuccessfulFetchAt,
  }) {
    return KdsState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      isRestaurantActive: isRestaurantActive ?? this.isRestaurantActive,
      lastSuccessfulFetchAt:
          lastSuccessfulFetchAt ?? this.lastSuccessfulFetchAt,
    );
  }
}

class KdsNotifier extends Notifier<KdsState> {
  ApiClient get _apiClient => ref.read(apiClientProvider);
  IO.Socket? _socket;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  int _socketReconnectAttempt = 0;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  @override
  KdsState build() {
    Future.microtask(() {
      fetchRestaurantStatus();
      fetchOrders();
      _initSocket();
      _startPolling();
    });

    ref.onDispose(() {
      _pollTimer?.cancel();
      _reconnectTimer?.cancel();
      _socket?.disconnect();
      _socket?.dispose();
      _eventController.close();
    });

    return KdsState();
  }

  /// Periodic polling every 10 seconds as a reliable fallback.
  /// This ensures new orders appear even if socket events are lost.
  void _startPolling() {
    _pollTimer?.cancel();
    final interval = state.isConnected
        ? const Duration(seconds: 30)
        : const Duration(seconds: 10);
    _pollTimer = Timer.periodic(interval, (_) {
      _fetchOrdersSilent();
    });
  }

  void _reschedulePolling() {
    _startPolling();
  }

  /// Silent fetch — doesn't set isLoading to avoid UI flicker.
  Future<void> _fetchOrdersSilent() async {
    try {
      final res = await _apiClient.get('/orders?limit=100');
      final allOrders = res.data as List<dynamic>;
      final prefs = ref.read(kitchenPreferencesProvider);

      final active = allOrders.where((o) {
        if (!prefs.showTestOrders &&
            (o['status'] == 'IGNORED_TEST' ||
                o['isTest'] == true ||
                o['ignoreInReporting'] == true)) {
          return false;
        }
        final section = OrderWorkflowMapper.getSection(
          OrderWorkflowMapper.getCanonicalStatus(o),
        );
        return section == KitchenSection.newOrders ||
            section == KitchenSection.preparing ||
            section == KitchenSection.ready ||
            section == KitchenSection.returned;
      }).toList();

      // Only update state if orders actually changed (compare by length + IDs)
      if (_ordersChanged(state.orders, active)) {
        state = state.copyWith(
          orders: active,
          lastSuccessfulFetchAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(lastSuccessfulFetchAt: DateTime.now());
      }
    } catch (e) {
      print('[KDS Poll] Error: $e');
    }
  }

  bool _ordersChanged(List<dynamic> old, List<dynamic> fresh) {
    if (old.length != fresh.length) return true;
    final oldIds = old.map((o) => '${o['id']}_${o['status']}').toSet();
    final freshIds = fresh.map((o) => '${o['id']}_${o['status']}').toSet();
    return !oldIds.containsAll(freshIds) || !freshIds.containsAll(oldIds);
  }

  Future<void> fetchRestaurantStatus() async {
    try {
      final res = await _apiClient.get('/restaurant/${AppConfig.restaurantId}');
      if (res.data != null && res.data['isActive'] != null) {
        state = state.copyWith(isRestaurantActive: res.data['isActive']);
      }
    } catch (e) {
      print('Error fetching restaurant status: $e');
    }
  }

  Future<void> toggleOnlineStatus(bool isActive) async {
    try {
      // Optimistic update
      state = state.copyWith(isRestaurantActive: isActive);
      await _apiClient.patch(
        '/admin/restaurant/profile',
        data: {'isActive': isActive},
      );
    } catch (e) {
      print('Error toggling online status: $e');
      // Revert on error
      state = state.copyWith(isRestaurantActive: !isActive);
    }
  }

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiClient.get('/orders?limit=100');
      // Only keep active kitchen orders
      final allOrders = res.data as List<dynamic>;
      final prefs = ref.read(kitchenPreferencesProvider);

      final active = allOrders.where((o) {
        if (!prefs.showTestOrders &&
            (o['status'] == 'IGNORED_TEST' ||
                o['isTest'] == true ||
                o['ignoreInReporting'] == true)) {
          return false;
        }
        final section = OrderWorkflowMapper.getSection(
          OrderWorkflowMapper.getCanonicalStatus(o),
        );
        return section == KitchenSection.newOrders ||
            section == KitchenSection.preparing ||
            section == KitchenSection.ready ||
            section == KitchenSection.returned;
      }).toList();
      state = state.copyWith(
        orders: active,
        isLoading: false,
        lastSuccessfulFetchAt: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching kitchen orders: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _initSocket() async {
    final token = await _apiClient.getToken();
    if (token == null) {
      print('[KDS Socket] No token, skipping socket init');
      // Retry after a delay
      _reconnectTimer = Timer(const Duration(seconds: 5), () => _initSocket());
      return;
    }

    // Clean up any existing socket
    _socket?.disconnect();
    _socket?.dispose();

    _socket = IO.io(
      '${AppConfig.socketUrl}/realtime',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableForceNew()
          .build(),
    );

    _socket?.onConnect((_) {
      print('[KDS Socket] Connected to /realtime');
      _socketReconnectAttempt = 0;
      state = state.copyWith(isConnected: true);
      _reschedulePolling();
      _fetchOrdersSilent();
    });

    _socket?.onDisconnect((_) {
      print('[KDS Socket] Disconnected');
      state = state.copyWith(isConnected: false);
      _reschedulePolling();
    });

    _socket?.onConnectError((err) {
      print('[KDS Socket] Connect Error: $err');
      state = state.copyWith(isConnected: false);
      _scheduleSocketReconnect();
    });

    _socket?.onReconnect((_) {
      print('[KDS Socket] Reconnected');
      state = state.copyWith(isConnected: true);
    });

    _socket?.on('order:status.changed', (data) {
      if (kDebugMode) {
        debugPrint('[KDS Socket] order:status.changed received');
      }
      _emitEvent(data);
      fetchOrders();
    });

    _socket?.on('order:created', (data) {
      if (kDebugMode) {
        debugPrint('[KDS Socket] order:created received');
      }
      _emitEvent(data);
      unawaited(_onNewOrderSignal(data));
      fetchOrders();
    });

    _socket?.connect();
    print('[KDS Socket] Connecting to ${AppConfig.socketUrl}/realtime ...');
  }

  void _scheduleSocketReconnect() {
    _reconnectTimer?.cancel();
    final seconds = switch (_socketReconnectAttempt) {
      0 => 3,
      1 => 6,
      2 => 15,
      _ => 30,
    };
    _socketReconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () => _initSocket());
  }

  Future<void> dispatchToPathao(
    String orderId, {
    required String trackingId,
    String? trackingUrl,
  }) async {
    try {
      await _apiClient.post(
        '/orders/$orderId/dispatch-external',
        data: {
          'deliveryService': 'Pathao Parcel',
          'trackingId': trackingId,
          if (trackingUrl != null && trackingUrl.isNotEmpty)
            'trackingUrl': trackingUrl,
        },
      );
      await fetchOrders();
    } catch (e) {
      print('Error dispatching to Pathao: $e');
      rethrow;
    }
  }

  void _emitEvent(dynamic data) {
    if (data is List && data.isNotEmpty) data = data.first;
    if (data is Map<String, dynamic>) {
      _eventController.add(data);
    } else if (data is Map) {
      _eventController.add(Map<String, dynamic>.from(data));
    }
  }

  Future<void> _onNewOrderSignal(dynamic data) async {
    final prefs = ref.read(kitchenPreferencesProvider);
    if (prefs.soundEnabled) {
      await ref.read(orderAlertServiceProvider).playNewOrderSound();
    }
  }

  Future<Map<String, dynamic>?> _fetchOrderDetail(String orderId) async {
    try {
      final res = await _apiClient.get('/orders/$orderId');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[KDS] fetch order $orderId failed: $e');
    }
    return null;
  }

  Future<void> _maybePrintKitchenTicket(String orderId) async {
    final prefs = ref.read(kitchenPreferencesProvider);
    if (!prefs.autoPrint) return;
    final order = await _fetchOrderDetail(orderId);
    if (order == null) return;
    await ref.read(printServiceProvider).printKitchenTicket(order);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Stop any playing alert sound when staff acknowledges an order
    ref.read(orderAlertServiceProvider).stopAlert();

    try {
      if (newStatus == 'ACCEPTED') {
        await _apiClient.post('/orders/$orderId/accept');
        await _maybePrintKitchenTicket(orderId);
      } else {
        await _apiClient.patch(
          '/orders/$orderId/status',
          data: {'status': newStatus},
        );
      }
      fetchOrders();
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating status: $e');
    }
  }

  Future<void> rejectOrder(String orderId, String note) async {
    try {
      await _apiClient.post('/orders/$orderId/reject', data: {'note': note});
      fetchOrders(); // refresh board
    } catch (e) {
      print('Error rejecting order: $e');
    }
  }

  Future<void> setFoodDisposition(String orderId, String disposition) async {
    try {
      await _apiClient.post(
        '/orders/$orderId/food-disposition',
        data: {'disposition': disposition},
      );
      await fetchOrders();
    } catch (e) {
      if (kDebugMode) debugPrint('Error setting food disposition: $e');
      rethrow;
    }
  }
}

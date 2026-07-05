import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../../../core/services/order_alert_service.dart';
import '../../../../core/services/print_service.dart';
import '../../../auth/providers/auth_provider.dart';
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
                KitchenSection.returned &&
            o['foodDisposition'] != 'DISCARDED',
      )
      .toList();
});

/// A StreamProvider that yields socket events so the UI can listen reactively.
final kdsEventStreamProvider = StreamProvider.autoDispose<Map<String, dynamic>>(
  (ref) {
    return ref.watch(kdsProvider.notifier).eventStream;
  },
);

/// A dispatch-related alert surfaced to the kitchen UI.
class DispatchAlert {
  final String orderId;
  final String orderNumber;
  final DispatchAlertType type;
  final String? riderName;
  final DateTime createdAt;

  const DispatchAlert({
    required this.orderId,
    required this.orderNumber,
    required this.type,
    this.riderName,
    required this.createdAt,
  });
}

enum DispatchAlertType {
  searching,
  accepted,
  rejected,
  expired,
  exhausted,
  failed,
}

class KdsState {
  final List<dynamic> orders;
  final bool isLoading;
  final bool isConnected;
  final bool isRestaurantActive;
  final DateTime? lastSuccessfulFetchAt;
  final String? lastPrintError;
  final Map<String, dynamic>? lastFailedOrder;
  final List<DispatchAlert> dispatchAlerts;

  KdsState({
    this.orders = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.isRestaurantActive = true,
    this.lastSuccessfulFetchAt,
    this.lastPrintError,
    this.lastFailedOrder,
    this.dispatchAlerts = const [],
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
    String? lastPrintError,
    Map<String, dynamic>? lastFailedOrder,
    List<DispatchAlert>? dispatchAlerts,
    bool clearPrintError = false,
  }) {
    return KdsState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      isRestaurantActive: isRestaurantActive ?? this.isRestaurantActive,
      lastSuccessfulFetchAt:
          lastSuccessfulFetchAt ?? this.lastSuccessfulFetchAt,
      lastPrintError: clearPrintError
          ? null
          : (lastPrintError ?? this.lastPrintError),
      lastFailedOrder: clearPrintError
          ? null
          : (lastFailedOrder ?? this.lastFailedOrder),
      dispatchAlerts: dispatchAlerts ?? this.dispatchAlerts,
    );
  }
}

class KdsNotifier extends Notifier<KdsState> {
  ApiClient get _apiClient => ref.read(apiClientProvider);
  IO.Socket? _socket;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  Timer? _debounceTimer;
  int _socketReconnectAttempt = 0;
  StreamSubscription<void>? _tokenRefreshSub;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  @override
  KdsState build() {
    // Re-fetch orders whenever kitchen preferences change (e.g. showTestOrders toggle).
    ref.listen(kitchenPreferencesProvider, (previous, next) {
      if (previous?.showTestOrders != next.showTestOrders) {
        Future.microtask(fetchOrders);
      }
    });

    // Re-fetch restaurant status whenever the authenticated user changes
    // (e.g. after login or app cold start with a saved token).
    ref.listen(authProvider, (previous, next) {
      final prevId = _extractRestaurantId(previous?.user);
      final nextId = _extractRestaurantId(next.user);
      if (prevId != nextId && next.status == AuthStatus.authenticated) {
        Future.microtask(() {
          fetchRestaurantStatus();
          fetchOrders();
        });
      }
    });

    Future.microtask(() {
      fetchRestaurantStatus();
      fetchOrders();
      _initSocket();
      _startPolling();
    });

    _tokenRefreshSub = _apiClient.tokenRefreshedStream.listen((_) {
      _initSocket();
    });

    ref.onDispose(() {
      _tokenRefreshSub?.cancel();
      _pollTimer?.cancel();
      _reconnectTimer?.cancel();
      _debounceTimer?.cancel();
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
        final section = OrderWorkflowMapper.getSection(
          OrderWorkflowMapper.getCanonicalStatus(
            o,
            includeTestOrders: prefs.showTestOrders,
          ),
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
      if (kDebugMode) debugPrint('[KDS Poll] Error: $e');
    }
  }

  bool _ordersChanged(List<dynamic> old, List<dynamic> fresh) {
    if (old.length != fresh.length) return true;
    final oldIds = old.map((o) => '${o['id']}_${o['status']}').toSet();
    final freshIds = fresh.map((o) => '${o['id']}_${o['status']}').toSet();
    return !oldIds.containsAll(freshIds) || !freshIds.containsAll(oldIds);
  }

  String? _extractRestaurantId(Map<String, dynamic>? user) {
    if (user == null) return null;

    final candidates = [user['restaurantId'], user['restaurant']?['id']];
    for (final value in candidates) {
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    if (kDebugMode && AppConfig.restaurantId.isNotEmpty) {
      return AppConfig.restaurantId;
    }
    return null;
  }

  String? get _authenticatedRestaurantId {
    return _extractRestaurantId(ref.read(authProvider).user);
  }

  Future<void> fetchRestaurantStatus() async {
    final restaurantId = _authenticatedRestaurantId;
    if (restaurantId == null || restaurantId.isEmpty) {
      if (kDebugMode)
        debugPrint(
          '[KDS] No authenticated restaurantId; skipping status fetch.',
        );
      return;
    }

    try {
      final res = await _apiClient.get('/restaurant/$restaurantId');
      if (res.data != null && res.data['isActive'] != null) {
        state = state.copyWith(isRestaurantActive: res.data['isActive']);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching restaurant status: $e');
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
      if (kDebugMode) debugPrint('Error toggling online status: $e');
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
        final section = OrderWorkflowMapper.getSection(
          OrderWorkflowMapper.getCanonicalStatus(
            o,
            includeTestOrders: prefs.showTestOrders,
          ),
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
      if (kDebugMode) debugPrint('Error fetching kitchen orders: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _initSocket() async {
    final token = await _apiClient.getToken();
    if (token == null) {
      if (kDebugMode) debugPrint('[KDS Socket] No token, skipping socket init');
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
      if (kDebugMode) debugPrint('[KDS Socket] Connected to /realtime');
      _socketReconnectAttempt = 0;
      state = state.copyWith(isConnected: true);
      _reschedulePolling();
      _fetchOrdersSilent();
    });

    _socket?.onDisconnect((_) {
      if (kDebugMode) debugPrint('[KDS Socket] Disconnected');
      state = state.copyWith(isConnected: false);
      _reschedulePolling();
    });

    _socket?.onConnectError((err) {
      if (kDebugMode) debugPrint('[KDS Socket] Connect Error: $err');
      state = state.copyWith(isConnected: false);
      _scheduleSocketReconnect();
    });

    _socket?.onReconnect((_) {
      if (kDebugMode) debugPrint('[KDS Socket] Reconnected');
      state = state.copyWith(isConnected: true);
    });

    _socket?.on('order:status.changed', (data) {
      if (kDebugMode) {
        debugPrint('[KDS Socket] order:status.changed received');
      }
      _emitEvent(data);
      _debouncedFetchOrders();
    });

    _socket?.on('order:created', (data) {
      if (kDebugMode) {
        debugPrint('[KDS Socket] order:created received');
      }
      _emitEvent(data);
      unawaited(_onNewOrderSignal(data));
      _debouncedFetchOrders();
    });

    _socket?.on('order:dispatch.failed', (data) {
      if (kDebugMode) debugPrint('[KDS Socket] order:dispatch.failed received');
      _handleDispatchAlert(data, DispatchAlertType.failed);
      _debouncedFetchOrders();
    });

    _socket?.on('order:dispatch.exhausted', (data) {
      if (kDebugMode)
        debugPrint('[KDS Socket] order:dispatch.exhausted received');
      _handleDispatchAlert(data, DispatchAlertType.exhausted);
      _debouncedFetchOrders();
    });

    _socket?.on('assignment:created', (data) {
      if (kDebugMode) debugPrint('[KDS Socket] assignment:created received');
      _handleDispatchAlert(data, DispatchAlertType.searching);
      _debouncedFetchOrders();
    });

    _socket?.on('assignment:accepted', (data) {
      if (kDebugMode) debugPrint('[KDS Socket] assignment:accepted received');
      _handleDispatchAlert(data, DispatchAlertType.accepted);
      _debouncedFetchOrders();
    });

    _socket?.on('assignment:rejected', (data) {
      if (kDebugMode) debugPrint('[KDS Socket] assignment:rejected received');
      _handleDispatchAlert(data, DispatchAlertType.rejected);
      _debouncedFetchOrders();
    });

    _socket?.on('assignment:expired', (data) {
      if (kDebugMode) debugPrint('[KDS Socket] assignment:expired received');
      _handleDispatchAlert(data, DispatchAlertType.expired);
      _debouncedFetchOrders();
    });

    _socket?.connect();
    if (kDebugMode)
      debugPrint(
        '[KDS Socket] Connecting to ${AppConfig.socketUrl}/realtime ...',
      );
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

  /// Bust rapid socket events into a single fetch to avoid UI churn.
  void _debouncedFetchOrders() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchOrders();
    });
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
      if (kDebugMode) debugPrint('Error dispatching to Pathao: $e');
      rethrow;
    }
  }

  void _handleDispatchAlert(dynamic data, DispatchAlertType type) {
    if (data is List && data.isNotEmpty) data = data.first;
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final orderId = map['orderId']?.toString() ?? '';
    final orderNumber = map['orderNumber']?.toString() ?? '';
    if (orderId.isEmpty) return;

    final riderName = map['riderName']?.toString();
    final alert = DispatchAlert(
      orderId: orderId,
      orderNumber: orderNumber,
      type: type,
      riderName: riderName,
      createdAt: DateTime.now(),
    );

    final alerts =
        state.dispatchAlerts.where((a) => a.orderId != orderId).toList()
          ..add(alert);
    state = state.copyWith(dispatchAlerts: alerts);
    _emitEvent(data);
  }

  void dismissDispatchAlert(String orderId) {
    final alerts = state.dispatchAlerts
        .where((a) => a.orderId != orderId)
        .toList();
    state = state.copyWith(dispatchAlerts: alerts);
  }

  Future<List<dynamic>> fetchAvailableRiders() async {
    try {
      final res = await _apiClient.get('/dispatch/riders/available');
      return (res.data as List<dynamic>?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('[KDS] Error fetching available riders: $e');
      return [];
    }
  }

  Future<void> autoAssignRider(String orderId) async {
    try {
      await _apiClient.post('/dispatch/orders/$orderId/auto-assign');
      _debouncedFetchOrders();
    } catch (e) {
      if (kDebugMode) debugPrint('[KDS] Error auto-assigning rider: $e');
      rethrow;
    }
  }

  Future<void> assignRider(String orderId, String riderProfileId) async {
    try {
      await _apiClient.post(
        '/dispatch/orders/$orderId/assign',
        data: {'riderProfileId': riderProfileId},
      );
      _debouncedFetchOrders();
    } catch (e) {
      if (kDebugMode) debugPrint('[KDS] Error assigning rider: $e');
      rethrow;
    }
  }

  Future<void> forceUnassign(String orderId, {String? reason}) async {
    try {
      await _apiClient.post(
        '/dispatch/orders/$orderId/force-unassign',
        data: {if (reason != null) 'reason': reason},
      );
      _debouncedFetchOrders();
    } catch (e) {
      if (kDebugMode) debugPrint('[KDS] Error force-unassigning: $e');
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
    try {
      await ref.read(printServiceProvider).printKitchenTicket(order);
      state = state.copyWith(clearPrintError: true);
    } catch (e) {
      final message = _printErrorMessage(e);
      state = state.copyWith(lastPrintError: message, lastFailedOrder: order);
      if (kDebugMode) debugPrint('[KDS] Print failed: $message');
    }
  }

  String _printErrorMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('sunmi') || text.contains('printer')) {
      return 'Sunmi printer not detected. Ticket not printed.';
    }
    return 'Kitchen ticket could not be printed.';
  }

  Future<void> retryLastKitchenTicket() async {
    final order = state.lastFailedOrder;
    if (order == null) return;
    try {
      await ref.read(printServiceProvider).printKitchenTicket(order);
      state = state.copyWith(clearPrintError: true);
    } catch (e) {
      state = state.copyWith(lastPrintError: _printErrorMessage(e));
    }
  }

  void dismissPrintFailure() {
    state = state.copyWith(clearPrintError: true);
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
      if (kDebugMode) debugPrint('Error rejecting order: $e');
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

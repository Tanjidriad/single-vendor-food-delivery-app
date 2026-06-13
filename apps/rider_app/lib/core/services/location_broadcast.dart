import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/orders/presentation/providers/location_provider.dart';
import '../../features/orders/presentation/providers/order_providers.dart';
import '../map/geo_point.dart';
import '../websockets/socket_service.dart';

/// An immutable, SDK-neutral description of a single rider location broadcast.
///
/// Produced by the pure [decideBroadcast] decision and consumed by the
/// [locationBroadcastProvider] coordinator, which forwards it to
/// `SocketService.sendLocation`. It carries the active order identifier plus
/// the position's latitude/longitude and an optional heading (Requirement
/// 6.3).
class LocationBroadcast {
  /// The active order this position belongs to.
  final String orderId;

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// Heading in degrees, when available from the location source.
  final double? heading;

  const LocationBroadcast({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    this.heading,
  });

  @override
  bool operator ==(Object other) =>
      other is LocationBroadcast &&
      other.orderId == orderId &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.heading == heading;

  @override
  int get hashCode => Object.hash(orderId, latitude, longitude, heading);

  @override
  String toString() =>
      'LocationBroadcast(orderId: $orderId, latitude: $latitude, '
      'longitude: $longitude, heading: $heading)';
}

/// Decides whether a position should be broadcast for the current order state.
///
/// Pure and side-effect-free (no socket I/O), so it can be property-tested in
/// isolation (Correctness Property 13).
///
/// Returns a [LocationBroadcast] **if and only if** an active order exists
/// ([activeOrderId] non-null and non-empty) AND a [position] is available;
/// otherwise returns `null` (Requirements 6.4, 6.5). When a broadcast is
/// returned it carries the [activeOrderId] together with the position's
/// latitude, longitude, and [heading] (Requirements 6.2, 6.3).
///
/// The decision depends only on the order id and position — it is deliberately
/// independent of whether the order-room join has completed, so broadcasting
/// proceeds regardless of join state (Requirement 6.2).
LocationBroadcast? decideBroadcast(
  String? activeOrderId,
  GeoPoint? position,
  double? heading,
) {
  if (activeOrderId == null || activeOrderId.isEmpty) return null;
  if (position == null) return null;
  return LocationBroadcast(
    orderId: activeOrderId,
    latitude: position.latitude,
    longitude: position.longitude,
    heading: heading,
  );
}

/// Coordinates the live rider GPS broadcast during an active delivery
/// (Requirement 6).
///
/// This is a lazy, side-effecting [Provider]: it is inert until something
/// activates it (the active delivery screen does so in task 14.1). Once
/// active it:
///
/// - watches [activeOrderProvider] to know whether an order is in progress,
/// - listens to [locationStreamProvider] for new GPS positions, and
/// - for each position, uses [decideBroadcast] to decide whether to emit.
///
/// When a broadcast is warranted it calls `SocketService.sendLocation` with
/// the order id and the position's coordinates (Requirements 6.2, 6.3). When
/// no active order exists, [decideBroadcast] returns `null` and nothing is
/// sent (Requirements 6.4, 6.5).
///
/// If the socket is disconnected when a position arrives, it attempts to
/// reconnect via `SocketService.connect()` so a later position can be
/// delivered — i.e. it reconnects before the next broadcast (Requirement 6.7).
///
/// Heading is not carried by the [GeoPoint] location stream, so `null` is
/// passed through; a future heading-aware source can supply it without
/// changing this coordinator.
final locationBroadcastProvider = Provider<void>((ref) {
  final socket = ref.watch(socketServiceProvider);
  final order = ref.watch(activeOrderProvider);
  final activeOrderId = order?['id']?.toString();

  ref.listen<AsyncValue<GeoPoint>>(locationStreamProvider, (previous, next) {
    final position = next.value;
    final broadcast = decideBroadcast(activeOrderId, position, null);
    if (broadcast == null) return;

    // Disconnected: reconnect now so the next position can be delivered,
    // rather than emitting into a dead socket (Requirement 6.7).
    if (!socket.isConnected) {
      socket.connect();
      return;
    }

    socket.sendLocation(
      orderId: broadcast.orderId,
      latitude: broadcast.latitude,
      longitude: broadcast.longitude,
      heading: broadcast.heading,
    );
  });
});

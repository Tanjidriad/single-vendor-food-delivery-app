import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/websockets/socket_service.dart';
import '../../../shift/presentation/providers/rider_online_controller.dart';

/// Keeps the realtime socket aligned with the current access token and
/// reconnects when the rider is online.
final socketLifecycleProvider = Provider<void>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socket = ref.watch(socketServiceProvider);

  final tokenSub = apiClient.tokenRefreshedStream.listen((_) async {
    if (!ref.read(isOnlineProvider)) return;
    debugPrint('[SocketLifecycle] Token refreshed — reconnecting socket');
    await socket.reconnect();
  });

  ref.onDispose(() {
    tokenSub.cancel();
  });
});

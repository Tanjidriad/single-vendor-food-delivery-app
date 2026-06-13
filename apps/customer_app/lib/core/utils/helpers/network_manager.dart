import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../popups/loaders.dart';

/// Riverpod-friendly connectivity helper (replaces GetX [NetworkManager]).
class NetworkConnectivity {
  NetworkConnectivity(this._connectivity);

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  void Function(String message)? onDisconnected;

  Future<void> startListening(BuildContext context) async {
    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        if (context.mounted) {
          AppLoaders.customToast(context, message: 'No internet connection');
        }
        onDisconnected?.call('No internet connection');
      }
    });
  }

  Future<void> dispose() => _subscription?.cancel() ?? Future.value();

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } on PlatformException {
      return false;
    }
  }
}

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final networkConnectivityProvider = Provider<NetworkConnectivity>((ref) {
  final service = NetworkConnectivity(ref.watch(connectivityProvider));
  ref.onDispose(service.dispose);
  return service;
});

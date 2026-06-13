import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_manager.dart';

/// Starts connectivity toasts for the subtree.
class NetworkListener extends ConsumerStatefulWidget {
  const NetworkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NetworkListener> createState() => _NetworkListenerState();
}

class _NetworkListenerState extends ConsumerState<NetworkListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(networkConnectivityProvider).startListening(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

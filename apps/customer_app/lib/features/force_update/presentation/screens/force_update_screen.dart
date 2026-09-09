import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_update_provider.dart';

/// Blocking screen shown when the installed build is below the server's minimum
/// supported version. There is intentionally no way back into the app.
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appUpdateProvider).valueOrNull;
    final url = status?.updateUrl ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 72),
                const SizedBox(height: 24),
                Text(
                  'Update required',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'A newer version of the app is required to continue. '
                  'Please update to keep ordering.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (url.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Update now'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

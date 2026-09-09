import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/version/version_check.dart';

class AppUpdateStatus {
  const AppUpdateStatus({required this.updateRequired, required this.updateUrl});

  final bool updateRequired;
  final String updateUrl;

  static const none = AppUpdateStatus(updateRequired: false, updateUrl: '');
}

/// Fetches the server version floor and compares it to the installed build.
/// Fails open (never blocks) on any network/parse error or timeout so a backend
/// hiccup can't lock users out of the app.
final appUpdateProvider = FutureProvider<AppUpdateStatus>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final res = await dio
        .get<Map<String, dynamic>>(ApiEndpoints.appConfig)
        .timeout(const Duration(seconds: 5));
    final data = res.data ?? const <String, dynamic>{};
    final min = data['minSupportedVersion'] as String? ?? '0.0.0';
    final android = data['android'];
    final updateUrl =
        (android is Map ? android['updateUrl'] as String? : null) ?? '';

    final info = await PackageInfo.fromPlatform();
    return AppUpdateStatus(
      updateRequired: isUpdateRequired(info.version, min),
      updateUrl: updateUrl,
    );
  } catch (_) {
    return AppUpdateStatus.none;
  }
});

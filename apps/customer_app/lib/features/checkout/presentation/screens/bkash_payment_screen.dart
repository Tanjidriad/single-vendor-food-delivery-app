import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/payments_repository.dart';

/// Opens the bKash hosted checkout page, then executes payment on the backend.
class BkashPaymentScreen extends ConsumerStatefulWidget {
  const BkashPaymentScreen({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.checkoutUrl,
    required this.callbackUrlPrefix,
  });

  final String orderId;
  final String paymentId;
  final String checkoutUrl;
  final String callbackUrlPrefix;

  @override
  ConsumerState<BkashPaymentScreen> createState() => _BkashPaymentScreenState();
}

class _BkashPaymentScreenState extends ConsumerState<BkashPaymentScreen> {
  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  late final WebViewController _controller;
  var _executing = false;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController()..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  WebViewController _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_mobileUserAgent)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_shouldComplete(request.url)) {
              _completePayment();
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null && _shouldComplete(url)) {
              _completePayment();
            }
          },
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      if (kDebugMode) {
        AndroidWebViewController.enableDebugging(true);
      }
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    return controller;
  }

  bool _shouldComplete(String url) {
    return url.startsWith(widget.callbackUrlPrefix);
  }

  Future<void> _completePayment() async {
    if (_executing || _completed) return;
    setState(() => _executing = true);

    try {
      await ref.read(paymentsRepositoryProvider).executeOnline(
            orderId: widget.orderId,
            paymentId: widget.paymentId,
          );
      _completed = true;
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment could not be completed. Please try again.')),
      );
      setState(() => _executing = false);
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.checkoutUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with bKash'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_executing)
            const ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextButton(
            onPressed: _openInBrowser,
            child: const Text('Having trouble? Open in browser'),
          ),
        ),
      ),
    );
  }
}

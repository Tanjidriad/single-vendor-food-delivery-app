import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  var _showHelp = true;

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
        SnackBar(content: Text('Payment failed: $e')),
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

  void _copyCode(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with bKash'),
        actions: [
          IconButton(
            tooltip: 'Sandbox help',
            onPressed: () => setState(() => _showHelp = !_showHelp),
            icon: Icon(_showHelp ? Icons.help_outline : Icons.help),
          ),
          TextButton(
            onPressed: _executing ? null : _completePayment,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_showHelp) _SandboxHelpBanner(onCopy: _copyCode),
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wallet 01770618575 · PIN is 5 digits: 12121 · OTP is 6 digits: 123456',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _openInBrowser,
                child: const Text('OTP not working? Open in browser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SandboxHelpBanner extends StatelessWidget {
  const _SandboxHelpBanner({required this.onCopy});

  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sandbox test codes',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _HelpRow(
              label: '1. Wallet number',
              value: '01770618575',
              onCopy: () => onCopy('Wallet', '01770618575'),
            ),
            const SizedBox(height: 6),
            _HelpRow(
              label: '2. bKash PIN (5 digits, not 6)',
              value: '12121',
              onCopy: () => onCopy('PIN', '12121'),
            ),
            const SizedBox(height: 6),
            _HelpRow(
              label: '3. OTP / verification (6 digits)',
              value: '123456',
              onCopy: () => onCopy('OTP', '123456'),
            ),
            const SizedBox(height: 8),
            Text(
              'If a screen shows 6 boxes for PIN, enter 12121 only — leave the last box empty.',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9A3412),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          tooltip: 'Copy',
          visualDensity: VisualDensity.compact,
          onPressed: onCopy,
          icon: const Icon(Icons.copy, size: 18),
        ),
      ],
    );
  }
}

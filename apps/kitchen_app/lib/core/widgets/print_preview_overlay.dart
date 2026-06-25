import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/print_preview_controller.dart';
import '../theme/app_colors.dart';

/// Wraps any widget tree and intercepts PrintPreviewController events.
/// Shows a thermal-receipt-style dialog when no Sunmi printer is available.
/// Only active in debug builds — zero overhead in release.
class PrintPreviewOverlay extends StatefulWidget {
  final Widget child;
  const PrintPreviewOverlay({super.key, required this.child});

  @override
  State<PrintPreviewOverlay> createState() => _PrintPreviewOverlayState();
}

class _PrintPreviewOverlayState extends State<PrintPreviewOverlay> {
  StreamSubscription<PrintPreviewEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = PrintPreviewController.instance.stream.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(PrintPreviewEvent event) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _PrintReceiptDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PrintReceiptDialog extends StatelessWidget {
  final PrintPreviewEvent event;
  const _PrintReceiptDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final isTicket = event.type == PrintPreviewType.kitchenTicket;
    final title = isTicket ? 'Kitchen Ticket Preview' : 'Z-Report Preview';
    final icon = isTicket ? Icons.receipt_long : Icons.summarize;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDE7),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.pandaPink.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEBUG MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Perforated top edge
            _PerforatedEdge(),

            // Receipt content
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  event.content,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Perforated bottom edge
            _PerforatedEdge(),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: event.content));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Receipt content copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pandaPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerforatedEdge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: CustomPaint(painter: _PerforationPainter()),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    const radius = 6.0;
    const spacing = 18.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, size.height / 2), radius, paint);
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) => false;
}

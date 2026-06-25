import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Shows a PIN entry dialog. Returns `true` if the entered PIN matches
/// [expectedPin]. Returns `false` if dismissed or wrong.
Future<bool> showPinPadDialog(
  BuildContext context, {
  required String expectedPin,
  String title = 'Manager PIN Required',
  String subtitle = 'Enter your 4-digit PIN to continue.',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => PinPadDialog(
      expectedPin: expectedPin,
      title: title,
      subtitle: subtitle,
    ),
  );
  return result == true;
}

class PinPadDialog extends StatefulWidget {
  final String expectedPin;
  final String title;
  final String subtitle;

  const PinPadDialog({
    super.key,
    required this.expectedPin,
    required this.title,
    required this.subtitle,
  });

  @override
  State<PinPadDialog> createState() => _PinPadDialogState();
}

class _PinPadDialogState extends State<PinPadDialog>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _isError = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_entered.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _entered += digit;
      _isError = false;
    });
    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _validate);
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _validate() {
    if (_entered == widget.expectedPin) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _isError = true);
      _shakeCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _entered = '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.pandaPinkLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  color: AppColors.pandaPink, size: 28),
            ),
            const SizedBox(height: 16),

            // Title & subtitle
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 28),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? AppColors.error
                          : filled
                              ? AppColors.pandaPink
                              : Colors.transparent,
                      border: Border.all(
                        color: _isError
                            ? AppColors.error
                            : filled
                                ? AppColors.pandaPink
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_isError) ...[
              const SizedBox(height: 10),
              Text(
                'Incorrect PIN — try again',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 28),

            // Numpad
            _buildNumpad(theme),

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(ThemeData theme) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 72, height: 60);
            if (key == '⌫') {
              return _numKey(
                child: const Icon(Icons.backspace_outlined, size: 20),
                onTap: _onBackspace,
                theme: theme,
                isBackspace: true,
              );
            }
            return _numKey(
              child: Text(
                key,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface),
              ),
              onTap: () => _onKey(key),
              theme: theme,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _numKey({
    required Widget child,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isBackspace = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isBackspace
              ? Colors.transparent
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
        child: child,
      ),
    );
  }
}

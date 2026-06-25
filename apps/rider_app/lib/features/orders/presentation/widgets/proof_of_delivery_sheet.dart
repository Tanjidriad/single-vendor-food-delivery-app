import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/orders_repository.dart';

/// Final-step proof-of-delivery sheet: the rider enters the customer's PIN to
/// verify and complete the delivery via [verifyDeliveryOtp].
class ProofOfDeliverySheet extends ConsumerStatefulWidget {
  const ProofOfDeliverySheet({
    super.key,
    required this.orderId,
    required this.onComplete,
    this.dropoffPhotoUrl,
    this.pickupExperience,
  });

  final String orderId;
  final VoidCallback onComplete;
  final String? dropoffPhotoUrl;
  final String? pickupExperience;

  @override
  ConsumerState<ProofOfDeliverySheet> createState() =>
      _ProofOfDeliverySheetState();
}

class _ProofOfDeliverySheetState extends ConsumerState<ProofOfDeliverySheet> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndComplete() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the delivery PIN');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ref.read(ordersRepositoryProvider).verifyDeliveryOtp(
            widget.orderId,
            otp,
            dropoffPhotoUrl: widget.dropoffPhotoUrl,
            pickupExperience: widget.pickupExperience,
          );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            // Lock badge to signal a secure handoff step.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Proof of Delivery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Enter the 4-digit PIN from the customer to complete',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // PIN input
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 12,
              ),
              decoration: const InputDecoration(
                hintText: '----',
                hintStyle: TextStyle(
                  fontSize: 28,
                  letterSpacing: 12,
                  color: AppColors.textDisabled,
                ),
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.offline,
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              text: 'Verify & Complete',
              icon: LucideIcons.check,
              isLoading: _isVerifying,
              onPressed: _isVerifying ? null : _verifyAndComplete,
            ),
          ],
        ),
      ),
    );
  }
}

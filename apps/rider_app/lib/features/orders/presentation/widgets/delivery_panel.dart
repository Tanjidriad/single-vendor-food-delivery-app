import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/feedback/success_snack.dart';
import '../../../../core/widgets/swipe_action.dart';
import '../../data/active_order_view.dart';
import '../../data/uploads_repository.dart';
import 'step_indicator.dart';

/// The bottom delivery panel: step indicator, destination + contact actions,
/// navigate handoff, payment summary, and the confirm swipe.
class DeliveryPanel extends ConsumerStatefulWidget {
  const DeliveryPanel({
    super.key,
    required this.order,
    required this.currentStep,
    required this.swipeNonce,
    required this.onNavigate,
    required this.onCall,
    required this.onMessage,
    required this.onCustomerUnavailable,
    required this.onSwipeConfirmed,
  });

  final ActiveOrderView order;
  final int currentStep;
  final int swipeNonce;
  final VoidCallback onNavigate;

  /// Null when the order has no phone, which hides the call control
  /// (Requirements 5.1, 5.5).
  final VoidCallback? onCall;
  final VoidCallback onMessage;

  /// Opens the report-a-problem flow seeded for a customer who cannot be
  /// reached at the door.
  final VoidCallback onCustomerUnavailable;
  final Future<void> Function(String? dropoffPhotoUrl, String? pickupExperience)
      onSwipeConfirmed;

  @override
  ConsumerState<DeliveryPanel> createState() => _DeliveryPanelState();
}

class _DeliveryPanelState extends ConsumerState<DeliveryPanel> {
  String? _dropoffPhotoUrl;
  String? _pickupExperience;
  bool _uploadingPhoto = false;

  bool get _atCustomer => widget.currentStep >= 2;

  String get _destinationName =>
      _atCustomer ? widget.order.customerName : widget.order.restaurantName;

  String get _destinationSubtitle =>
      _atCustomer ? widget.order.deliveryAddress : 'Pickup location';

  String get _swipeLabel {
    switch (widget.currentStep) {
      case 0:
        return 'Swipe — Arrived at Restaurant';
      case 1:
        return 'Swipe to Confirm Pickup';
      case 2:
        return 'Swipe — Start Delivery';
      case 3:
        return 'Swipe — Arrived at Customer';
      default:
        return 'Swipe to Complete';
    }
  }

  void _setPickupExperience(String value) {
    setState(() {
      // Tapping the selected chip again clears the choice.
      _pickupExperience = _pickupExperience == value ? null : value;
    });
  }

  Future<void> _takeDropoffPhoto() async {
    if (_uploadingPhoto) return;

    if (kDebugMode) {
      setState(() => _dropoffPhotoUrl = 'https://picsum.photos/400/400');
      return;
    }

    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    // Upload the captured file and keep only the hosted URL. Sending a local
    // device path to the backend is meaningless — the photo must be uploaded
    // first so proof-of-delivery survives on the server and in support views.
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref
          .read(uploadsRepositoryProvider)
          .uploadDeliveryProof(photo.path);
      if (!mounted) return;
      setState(() {
        _dropoffPhotoUrl = url;
        _uploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.offline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCod = widget.order.paymentMethod == 'COD';
    final cashAmount = (isCod && widget.order.grandTotal != null)
        ? formatCurrency(widget.order.grandTotal!)
        : formatCurrency(0);

    return Container(
      width: double.infinity,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        border: const Border(top: BorderSide(color: AppColors.borderDark)),
        boxShadow: AppShadows.medium,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BottomSheetHandle(),
                const SizedBox(height: AppSpacing.sm),

                // Horizontal step indicator (Requirements 4.1, 4.2).
                StepIndicator(currentStep: widget.currentStep),
                const SizedBox(height: AppSpacing.xxl),

                // Destination + contact actions.
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _atCustomer ? LucideIcons.user : LucideIcons.store,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _destinationName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _destinationSubtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy address',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _destinationSubtitle),
                        );
                        SuccessSnack.show(context, 'Address copied');
                      },
                      icon: const Icon(
                        LucideIcons.copy,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Chat entry — distinct from the call control (Req 5.3, 5.4).
                    _RoundActionButton(
                      icon: LucideIcons.messageSquare,
                      color: AppColors.inProgress,
                      tooltip: 'Message customer',
                      onTap: widget.onMessage,
                    ),
                    // Call control — shown only when a phone is present
                    // (Requirements 5.1, 5.5).
                    if (widget.onCall != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      _RoundActionButton(
                        icon: LucideIcons.phone,
                        color: AppColors.online,
                        tooltip: 'Call customer',
                        onTap: widget.onCall!,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Collapsible order items
                if (widget.order.items.isNotEmpty)
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.primary,
                      title: Text(
                        '${widget.order.items.length} items',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      children: widget.order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.addons.isNotEmpty)
                                      Text(
                                        item.addons.join(', '),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCurrency(item.unitPrice * item.quantity),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(color: AppColors.borderDark),
                const SizedBox(height: AppSpacing.md),

                // Payment summary
                if (!_atCustomer)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No payment at pickup',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (isCod)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            LucideIcons.checkCircle2,
                            color: AppColors.online,
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Total payment',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 28,
                          top: 4,
                          bottom: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Collect cash from customer',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cashAmount,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Confirm this cash when you complete the delivery — '
                              'it is added to your cash-to-deposit total.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                if (_atCustomer)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(
                          _dropoffPhotoUrl != null
                              ? LucideIcons.checkCircle2
                              : LucideIcons.camera,
                          color: _dropoffPhotoUrl != null
                              ? AppColors.online
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dropoffPhotoUrl != null
                                    ? 'Photo attached'
                                    : "Photo at the customer's door",
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_dropoffPhotoUrl == null)
                                const Text(
                                  'Add a photo as proof of drop-off',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_dropoffPhotoUrl == null)
                          InkWell(
                            onTap: _uploadingPhoto ? null : _takeDropoffPhoto,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  if (_uploadingPhoto)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      LucideIcons.camera,
                                      size: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _uploadingPhoto ? 'Uploading…' : 'Add photo',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                if (!_atCustomer)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How is the pick up experience?',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              _PickupExperienceChip(
                                icon: LucideIcons.thumbsUp,
                                label: 'Good',
                                value: 'GOOD',
                                selected: _pickupExperience == 'GOOD',
                                onTap: _setPickupExperience,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _PickupExperienceChip(
                                icon: LucideIcons.thumbsDown,
                                label: 'Bad',
                                value: 'BAD',
                                selected: _pickupExperience == 'BAD',
                                onTap: _setPickupExperience,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_atCustomer)
                  InkWell(
                    onTap: widget.onCustomerUnavailable,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customer unavailable',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                // External navigation handoff (Requirements 4.3, 4.4, 4.5).
                OutlinedButton.icon(
                  onPressed: widget.onNavigate,
                  icon: const Icon(LucideIcons.navigation, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  label: const Text(
                    'Navigate',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Confirm swipe driving the DeliveryProgressController
                SwipeAction(
                  key: ValueKey(
                    'confirm-swipe-${widget.currentStep}-${widget.swipeNonce}',
                  ),
                  label: _swipeLabel,
                  icon: LucideIcons.chevronsRight,
                  onConfirmed: () => widget.onSwipeConfirmed(
                    _dropoffPhotoUrl,
                    _pickupExperience,
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

/// A round, tinted contact-action button (call / message).
class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

/// A selectable good/bad chip used to capture the rider's pickup experience.
class _PickupExperienceChip extends StatelessWidget {
  const _PickupExperienceChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderDark,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

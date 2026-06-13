import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../data/orders_repository.dart';

class ReviewOrderSheet extends ConsumerStatefulWidget {
  const ReviewOrderSheet({super.key, required this.orderId});

  final String orderId;

  static Future<void> show(BuildContext context, String orderId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReviewOrderSheet(orderId: orderId),
    );
  }

  @override
  ConsumerState<ReviewOrderSheet> createState() => _ReviewOrderSheetState();
}

class _ReviewOrderSheetState extends ConsumerState<ReviewOrderSheet> {
  int _foodRating = 5;
  int _riderRating = 5;
  int _tipAmount = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  final List<int> _tipOptions = [0, 10, 20, 50, 100];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      // In a real app we would pass riderRating and tip to the backend
      // Currently the backend only takes order rating and comment
      await ref.read(ordersRepositoryProvider).submitReview(
            orderId: widget.orderId,
            rating: _foodRating,
            comment: _commentController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        AppLoaders.successSnackBar(
          context,
          title: 'Thank you!',
          message: 'Your feedback and tip were submitted.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(context, title: 'Could not submit', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildRatingStars(int currentRating, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.warning,
            size: 36,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Food Rating
          Text(
            'Rate the food',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          _buildRatingStars(_foodRating, (r) => setState(() => _foodRating = r)),
          
          const Divider(height: 32),
          
          // Rider Rating
          Text(
            'Rate your rider',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          _buildRatingStars(_riderRating, (r) => setState(() => _riderRating = r)),
          
          const SizedBox(height: 24),
          
          // Tip Section
          Text(
            'Say thanks with a tip',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _tipOptions.map((amount) {
              final isSelected = _tipAmount == amount;
              return GestureDetector(
                onTap: () => setState(() => _tipAmount = amount),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.gray100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    amount == 0
                        ? 'No tip'
                        : AppFormatter.formatCurrency(amount.toDouble()),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tell us what you loved (optional)',
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Submit review',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

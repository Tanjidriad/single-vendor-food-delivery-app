import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../data/addresses_repository.dart';
import '../providers/addresses_providers.dart';
import '../providers/checkout_address_provider.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../widgets/add_address_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key, this.selectForCheckout = false});

  final bool selectForCheckout;

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? editAddress,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddAddressSheet(editAddress: editAddress),
    );
    if (saved == true) ref.invalidate(addressesListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesListProvider);
    final selectedId = ref.watch(selectedCheckoutAddressProvider)?['id'];
    final isDark = AppHelperFunctions.isDarkMode(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectForCheckout ? 'Choose address' : 'Addresses'),
      ),
      body: addresses.when(
        data: (list) {
          return Column(
            children: [
              Expanded(
                child: list.isEmpty ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 56,
                          color: isDark ? AppColors.white700 : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved addresses',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a delivery address to place orders.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.white700 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ) : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = list[i] as Map<String, dynamic>;
                    final id = a['id'] as String;
                    final isSelected = selectedId == id;
                    final label = a['label'] as String? ?? 'Address';
                    final line1 = a['line1'] as String? ?? '';
                    final city = a['city'] as String?;
                    final isDefault = a['isDefault'] == true;

                    return Material(
                      color: isDark ? AppColors.black400 : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        onTap: selectForCheckout
                            ? () {
                                ref
                                    .read(selectedCheckoutAddressProvider.notifier)
                                    .state = a;
                                context.pop();
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : AppColors.border),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.white700
                                        : AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          label,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(
                                                AppSpacing.radiusPill,
                                              ),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      city != null ? '$line1, $city' : line1,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppColors.white700
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!selectForCheckout)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _openSheet(
                                        context,
                                        ref,
                                        editAddress: a,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        await ref
                                            .read(addressesRepositoryProvider)
                                            .delete(id);
                                        if (selectedId == id) {
                                          ref
                                              .read(
                                                selectedCheckoutAddressProvider
                                                    .notifier,
                                              )
                                              .state = null;
                                        }
                                        ref.invalidate(addressesListProvider);
                                      },
                                    ),
                                  ],
                                )
                              else if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: AppButton(
                  label: 'Add address',
                  onPressed: () => _openSheet(context, ref),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(addressesListProvider),
        ),
      ),
    );
  }
}

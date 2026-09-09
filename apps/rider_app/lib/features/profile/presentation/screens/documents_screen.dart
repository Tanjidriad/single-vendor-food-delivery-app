import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../onboarding/data/onboarding_repository.dart';
import '../providers/rider_profile_provider.dart';
import '../widgets/profile_ui_primitives.dart';

/// Verification documents: one row per document type with its review status
/// and an upload action. Reached from the profile "Documents" row.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  RiderDocType? _uploading;

  Future<void> _upload(RiderDocType type) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploading = type);
      await ref.read(onboardingRepositoryProvider).uploadDocument(
            type: type,
            filePath: picked.path,
            fileName: picked.name,
          );
      ref.invalidate(riderProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.offline,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(riderProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Documents',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.chevronLeft),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceLight,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const TabLoadingView(),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(riderProfileProvider),
        ),
        data: (profile) {
          String? statusFor(String wireType) {
            for (final d in profile.documents) {
              if (d.type == wireType) return d.status;
            }
            return null;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.section,
            ),
            children: [
              Text(
                'Upload clear photos of your documents. Reviews usually '
                'complete within 24 hours.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ProfileSectionCard(
                child: Column(
                  children: [
                    for (var i = 0; i < RiderDocType.values.length; i++)
                      _DocumentRow(
                        label: RiderDocType.values[i].label,
                        status: statusFor(RiderDocType.values[i].wire),
                        busy: _uploading == RiderDocType.values[i],
                        onTap: _uploading == null
                            ? () => _upload(RiderDocType.values[i])
                            : null,
                        showDivider: i < RiderDocType.values.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.label,
    required this.status,
    required this.busy,
    required this.onTap,
    required this.showDivider,
  });

  final String label;
  final String? status;
  final bool busy;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final (Color color, String text) = switch (status) {
      'APPROVED' => (AppColors.online, 'Approved'),
      'REJECTED' => (AppColors.offline, 'Rejected'),
      'PENDING' => (AppColors.busy, 'In review'),
      _ => (AppColors.textSecondary, 'Missing'),
    };

    final needsUpload = status == null || status == 'REJECTED';

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else ...[
                  LabelChip(label: text, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    needsUpload
                        ? LucideIcons.cloudUpload
                        : LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textDisabled,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }
}

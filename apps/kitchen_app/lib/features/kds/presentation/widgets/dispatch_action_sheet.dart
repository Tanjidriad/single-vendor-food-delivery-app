import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/kds_provider.dart';

class DispatchActionSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String orderNumber;
  final bool hasActiveAssignment;

  const DispatchActionSheet({
    super.key,
    required this.orderId,
    required this.orderNumber,
    this.hasActiveAssignment = false,
  });

  @override
  ConsumerState<DispatchActionSheet> createState() =>
      _DispatchActionSheetState();
}

class _DispatchActionSheetState extends ConsumerState<DispatchActionSheet> {
  List<dynamic>? _riders;
  bool _loadingRiders = true;
  bool _actionInProgress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  Future<void> _fetchRiders() async {
    setState(() {
      _loadingRiders = true;
      _error = null;
    });
    try {
      final riders = await ref.read(kdsProvider.notifier).fetchAvailableRiders();
      if (mounted) setState(() { _riders = riders; _loadingRiders = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Could not load riders'; _loadingRiders = false; });
      }
    }
  }

  Future<void> _autoAssign() async {
    setState(() { _actionInProgress = true; _error = null; });
    try {
      await ref.read(kdsProvider.notifier).autoAssignRider(widget.orderId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'Auto-assign failed. No riders may be available.'; _actionInProgress = false; });
      }
    }
  }

  Future<void> _assignRider(String riderProfileId) async {
    setState(() { _actionInProgress = true; _error = null; });
    try {
      await ref.read(kdsProvider.notifier).assignRider(widget.orderId, riderProfileId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'Failed to assign rider'; _actionInProgress = false; });
      }
    }
  }

  Future<void> _forceUnassign() async {
    setState(() { _actionInProgress = true; _error = null; });
    try {
      await ref.read(kdsProvider.notifier).forceUnassign(widget.orderId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'Failed to unassign rider'; _actionInProgress = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dispatch — Order #${widget.orderNumber}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),

          // Auto-assign button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _actionInProgress ? null : _autoAssign,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: const Text('Auto-assign best rider'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Force unassign (only if there's an active assignment)
          if (widget.hasActiveAssignment) ...[
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _actionInProgress ? null : _forceUnassign,
                icon: const Icon(Icons.person_remove_rounded, size: 16),
                label: const Text('Force unassign current rider'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Available riders list
          Text(
            'Available riders',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          if (_loadingRiders)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else if (_riders == null || _riders!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pedal_bike_rounded, size: 32, color: AppColors.gray700),
                    const SizedBox(height: 8),
                    Text(
                      'No riders available right now',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _riders!.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rider = _riders![index] as Map<String, dynamic>;
                  final name = rider['fullName']?.toString() ?? 'Rider';
                  final activeCount = rider['_count']?['assignments'] ?? 0;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.pedal_bike_rounded, size: 18, color: AppColors.primary),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '$activeCount active delivery${activeCount == 1 ? '' : 'ies'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.gray700,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 80,
                      height: 32,
                      child: FilledButton(
                        onPressed: _actionInProgress
                            ? null
                            : () => _assignRider(rider['id'] as String),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Assign'),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_actionInProgress)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

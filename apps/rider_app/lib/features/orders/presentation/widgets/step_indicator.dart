import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/delivery_state_model.dart';

/// A horizontal progress indicator for the active delivery flow.
///
/// Renders the four delivery stages in order — Restaurant → Pickup → Customer
/// → Delivered (Requirement 4.1) — and highlights the stage that corresponds
/// to the current delivery step (Requirement 4.2). The active step is mapped to
/// its [DeliveryStage] via the pure [DeliveryStateModel.stageForStep] mapping so
/// the screen can pass `deliveryStepProvider` directly.
///
/// Stages before the active one are marked as completed (a check mark), the
/// active stage is emphasized, and later stages are muted. Completed/active
/// nodes and the connectors leading up to them use the teal [AppColors.primary];
/// inactive nodes and connectors use a muted border token. The widget adapts to
/// the active light/dark theme (Requirement 11.4).
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.currentStep});

  /// The current delivery step held by `deliveryStepProvider`
  /// (0 = heading to restaurant, 1 = at restaurant/pickup, 2 = heading to
  /// customer). Mapped to the active [DeliveryStage] internally.
  final int currentStep;

  /// The stages rendered, left to right, in delivery order.
  static const List<DeliveryStage> _stages = <DeliveryStage>[
    DeliveryStage.restaurant,
    DeliveryStage.pickup,
    DeliveryStage.customer,
    DeliveryStage.delivered,
  ];

  static const double _nodeSize = 36;

  IconData _iconFor(DeliveryStage stage) {
    switch (stage) {
      case DeliveryStage.restaurant:
        return LucideIcons.store;
      case DeliveryStage.pickup:
        return LucideIcons.shoppingBag;
      case DeliveryStage.customer:
        return LucideIcons.user;
      case DeliveryStage.delivered:
        return LucideIcons.flag;
    }
  }

  String _labelFor(DeliveryStage stage) {
    switch (stage) {
      case DeliveryStage.restaurant:
        return 'Restaurant';
      case DeliveryStage.pickup:
        return 'Pickup';
      case DeliveryStage.customer:
        return 'Customer';
      case DeliveryStage.delivered:
        return 'Delivered';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedLine = isDark ? AppColors.borderDark : AppColors.borderLight;
    const mutedIcon = AppColors.textSecondary;
    final activeLabel = isDark ? AppColors.textInverse : AppColors.textOnLight;
    const mutedLabel = AppColors.textSecondary;
    // Unreached nodes sit on the delivery panel (surfaceDark); use the raised
    // surface so they stay visible instead of blending into the panel.
    final mutedNodeFill =
        isDark ? AppColors.surfaceElevated : AppColors.surfaceLight;

    final activeStage = DeliveryStateModel.stageForStep(currentStep);
    final activeIndex = activeStage.index;

    final children = <Widget>[];
    for (var i = 0; i < _stages.length; i++) {
      final stage = _stages[i];
      final isCompleted = i < activeIndex;
      final isActive = i == activeIndex;
      final isReached = i <= activeIndex; // completed or active

      // Connector leading into this node (skipped before the first node).
      if (i > 0) {
        // The segment is "filled" once its right-hand node has been reached.
        final filled = i <= activeIndex;
        children.add(
          Expanded(
            child: Padding(
              // Offset the 2px line down so it aligns with the circle centers
              // (which sit `_nodeSize / 2` below the top of each node column).
              padding: const EdgeInsets.only(top: _nodeSize / 2 - 1),
              child: Container(
                height: 2,
                color: filled ? AppColors.primary : mutedLine,
              ),
            ),
          ),
        );
      }

      children.add(
        _StepNode(
          icon: isCompleted ? LucideIcons.check : _iconFor(stage),
          label: _labelFor(stage),
          isReached: isReached,
          isActive: isActive,
          nodeSize: _nodeSize,
          reachedColor: AppColors.primary,
          mutedLineColor: mutedLine,
          mutedIconColor: mutedIcon,
          mutedNodeFill: mutedNodeFill,
          activeLabelColor: activeLabel,
          mutedLabelColor: mutedLabel,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.icon,
    required this.label,
    required this.isReached,
    required this.isActive,
    required this.nodeSize,
    required this.reachedColor,
    required this.mutedLineColor,
    required this.mutedIconColor,
    required this.mutedNodeFill,
    required this.activeLabelColor,
    required this.mutedLabelColor,
  });

  final IconData icon;
  final String label;
  final bool isReached;
  final bool isActive;
  final double nodeSize;
  final Color reachedColor;
  final Color mutedLineColor;
  final Color mutedIconColor;
  final Color mutedNodeFill;
  final Color activeLabelColor;
  final Color mutedLabelColor;

  @override
  Widget build(BuildContext context) {
    final circleColor = isReached ? reachedColor : mutedNodeFill;
    final borderColor = isReached ? reachedColor : mutedLineColor;
    final iconColor = isReached ? Colors.white : mutedIconColor;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: reachedColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isReached ? activeLabelColor : mutedLabelColor,
            ),
          ),
        ],
      ),
    );
  }
}

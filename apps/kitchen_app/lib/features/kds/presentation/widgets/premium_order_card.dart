import 'package:flutter/material.dart';
import 'order_detail_sheet.dart';
import 'order_tile.dart';

/// Foodpanda-style order card for the KDS.
///
/// Displays a compact, scannable tile in the kanban column. Tapping the tile
/// opens a bottom sheet with full order details, modifiers, notes, rider info,
/// and the primary action.
class PremiumOrderCard extends StatelessWidget {
  final dynamic order;
  final String? nextStatus;
  final String actionText;
  final VoidCallback onAction;
  final VoidCallback? onReject;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final Color accentColor;

  const PremiumOrderCard({
    super.key,
    required this.order,
    required this.nextStatus,
    required this.actionText,
    required this.onAction,
    this.onReject,
    this.secondaryActionText,
    this.onSecondaryAction,
    required this.accentColor,
  });

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderDetailSheet(
        order: order,
        nextStatus: nextStatus,
        actionText: actionText,
        onAction: onAction,
        onReject: onReject,
        secondaryActionText: secondaryActionText,
        onSecondaryAction: onSecondaryAction,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrderTile(
      order: order,
      nextStatus: nextStatus,
      actionText: actionText,
      onAction: onAction,
      onReject: onReject,
      onTap: () => _openDetail(context),
      accentColor: accentColor,
    );
  }
}

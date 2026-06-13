import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';

/// A prominently styled widget for displaying special order-level instructions,
/// delivery notes, and allergy warnings.
///
/// Designed to be eye-catching (red/warning styling) so kitchen staff never
/// miss important customer notes that could affect food preparation.
class OrderNotesHighlight extends StatelessWidget {
  /// The delivery note or special instruction text.
  final String? deliveryNote;

  /// Any special item-level notes collected from all items.
  final List<String> itemNotes;

  const OrderNotesHighlight({
    super.key,
    this.deliveryNote,
    this.itemNotes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasDeliveryNote =
        deliveryNote != null && deliveryNote!.trim().isNotEmpty;
    final hasItemNotes = itemNotes.isNotEmpty;

    if (!hasDeliveryNote && !hasItemNotes) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Iconsax.warning_2, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'SPECIAL INSTRUCTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Delivery note
          if (hasDeliveryNote) ...[
            Text(
              deliveryNote!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            if (hasItemNotes) const SizedBox(height: 8),
          ],

          // Item-level notes
          ...itemNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error.withValues(alpha: 0.8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to extract item-level notes from order items list.
  static List<String> extractItemNotes(List<dynamic>? items) {
    if (items == null) return [];
    final notes = <String>[];
    for (final item in items) {
      final note = item['notes']?.toString().trim() ?? '';
      if (note.isNotEmpty) {
        final name = item['name'] ?? 'Item';
        notes.add('$name: $note');
      }
    }
    return notes;
  }
}

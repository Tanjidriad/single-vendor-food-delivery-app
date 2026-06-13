import 'package:flutter/material.dart';

import '../chips/app_chip.dart';

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AppFilterChip(
            label: 'All',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          ...categories.map((c) {
            final id = c['id'] as String;
            return AppFilterChip(
              label: c['name'] as String? ?? '',
              selected: selectedId == id,
              onTap: () => onSelected(id),
            );
          }),
        ],
      ),
    );
  }
}

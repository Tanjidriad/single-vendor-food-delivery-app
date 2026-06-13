import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common/breadcrumbs_with_heading.dart';
import '../../../../core/widgets/common/rounded_container.dart';
import '../../../../core/widgets/data_table/paginated_data_table.dart';
import '../../data/menu_repository.dart';
import '../dialogs/addon_editor_dialog.dart';

class AddonsManagementScreen extends ConsumerWidget {
  const AddonsManagementScreen({super.key});

  void _showEditor(BuildContext context, [dynamic addon]) {
    showDialog(
      context: context,
      builder: (ctx) => AddonEditorDialog(addon: addon),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addonsAsync = ref.watch(addonsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbsWithHeading(
            heading: 'Add-ons Management',
            breadcrumbItems: const ['Dashboard', 'Menu', 'Add-ons'],
            trailing: ElevatedButton.icon(
              onPressed: () => _showEditor(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add New Add-on'),
            ),
          ),
          const SizedBox(height: 24),
          
          RoundedContainer(
            padding: const EdgeInsets.all(0),
            child: addonsAsync.when(
              loading: () => const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SizedBox(
                height: 400,
                child: Center(child: Text('Error: $err')),
              ),
              data: (addons) {
                return PaginatedDataTableWidget(
                  source: AddonDataSource(addons, context, ref, this),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic addonData) async {
    final name = addonData['name'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Add-on?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final repo = ref.read(menuRepositoryProvider);
        await repo.deleteAddon(addonData['id']);
        ref.invalidate(addonsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  void _toggleStatus(WidgetRef ref, dynamic addonData, bool val) async {
     try {
        final repo = ref.read(menuRepositoryProvider);
        await repo.updateAddon(addonData['id'], {'isActive': val});
        ref.invalidate(addonsProvider);
      } catch (_) {}
  }
}

class AddonDataSource extends DataTableSource {
  final List<dynamic> addons;
  final BuildContext context;
  final WidgetRef ref;
  final AddonsManagementScreen screen;

  AddonDataSource(this.addons, this.context, this.ref, this.screen);

  @override
  DataRow? getRow(int index) {
    if (index >= addons.length) return null;
    final addon = addons[index];
    final name = addon['name'] ?? '';
    final price = '\$${(addon['price'] as num? ?? 0).toStringAsFixed(2)}';
    final isActive = addon['isActive'] ?? false;

    return DataRow(
      cells: [
        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary))),
        DataCell(
          Switch(
            value: isActive,
            onChanged: (val) => screen._toggleStatus(ref, addon, val),
            activeThumbColor: AppColors.success,
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                onPressed: () => screen._showEditor(context, addon),
                tooltip: 'Edit Add-on',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () => screen._confirmDelete(context, ref, addon),
                tooltip: 'Delete Add-on',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => addons.length;

  @override
  int get selectedRowCount => 0;
}

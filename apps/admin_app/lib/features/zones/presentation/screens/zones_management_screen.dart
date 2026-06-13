import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../providers/zones_provider.dart';
import '../dialogs/zone_dialog.dart';

class ZonesManagementScreen extends ConsumerWidget {
  const ZonesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zonesProvider);
    final zones = state.zones;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Zones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Zone'),
                style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: colors.onPrimary),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const ZoneDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(state.error!, style: TextStyle(color: colors.error)),
            ),
          Expanded(
            child: state.isLoading && zones.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    color: colors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.border),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Details')),
                            DataColumn(label: Text('Active')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: zones.map((zone) {
                            final isPolygon = zone.polygonGeo != null;
                            return DataRow(
                              cells: [
                                DataCell(Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPolygon ? colors.infoLight : colors.warningLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isPolygon ? 'Polygon' : 'Radius',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isPolygon ? colors.info : colors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(isPolygon ? 'Custom Shape' : '${zone.maxDistanceKm} Km')),
                                DataCell(
                                  Switch(
                                    value: zone.isActive,
                                    activeThumbColor: colors.primary,
                                    onChanged: (val) {
                                      ref.read(zonesProvider.notifier).toggleZoneActive(zone.id, val);
                                    },
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (ctx) => ZoneDialog(zone: zone),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: colors.error),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Zone'),
                                              content: Text("Are you sure you want to delete '${zone.name}'?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(foregroundColor: colors.error),
                                                  onPressed: () {
                                                    ref.read(zonesProvider.notifier).deleteZone(zone.id);
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

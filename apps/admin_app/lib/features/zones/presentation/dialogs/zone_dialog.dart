import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../providers/zones_provider.dart';

class ZoneDialog extends ConsumerStatefulWidget {
  final Zone? zone;

  const ZoneDialog({super.key, this.zone});

  @override
  ConsumerState<ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends ConsumerState<ZoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _radiusCtrl;
  late TextEditingController _geoJsonCtrl;
  bool _isActive = true;
  bool _isPolygonMode = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.zone?.name ?? '');
    _radiusCtrl = TextEditingController(
        text: widget.zone?.maxDistanceKm?.toString() ?? '');
    
    final geo = widget.zone?.polygonGeo;
    _geoJsonCtrl = TextEditingController(
      text: geo != null ? const JsonEncoder.withIndent('  ').convert(geo) : '',
    );
    
    _isActive = widget.zone?.isActive ?? true;
    _isPolygonMode = geo != null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      title: Text(widget.zone == null ? 'Create Delivery Zone' : 'Edit Delivery Zone'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMsg != null) ...[
                  Text(_errorMsg!, style: TextStyle(color: colors.error)),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Zone Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Mode Toggle
                Row(
                  children: [
                    const Text('Zone Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Radius (Km)'),
                      selected: !_isPolygonMode,
                      onSelected: (val) {
                        if (val) setState(() => _isPolygonMode = false);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Custom Polygon'),
                      selected: _isPolygonMode,
                      onSelected: (val) {
                        if (val) setState(() => _isPolygonMode = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!_isPolygonMode)
                  TextFormField(
                    controller: _radiusCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Max Distance (Km)',
                      border: OutlineInputBorder(),
                      helperText: 'E.g., 5.5 for a 5.5km radius from the restaurant',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (!_isPolygonMode && (v == null || v.isEmpty)) return 'Radius is required';
                      if (!_isPolygonMode && double.tryParse(v!) == null) return 'Must be a valid number';
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _geoJsonCtrl,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'GeoJSON Polygon',
                      border: OutlineInputBorder(),
                      helperText: 'Paste a valid GeoJSON Polygon object (e.g. from geojson.io)',
                    ),
                    validator: (v) {
                      if (_isPolygonMode && (v == null || v.isEmpty)) return 'GeoJSON is required';
                      if (_isPolygonMode) {
                        try {
                          final parsed = jsonDecode(v!);
                          if (parsed['type'] != 'Polygon' && parsed['type'] != 'MultiPolygon') {
                            return 'Root object must be a Polygon or MultiPolygon';
                          }
                        } catch (e) {
                          return 'Invalid JSON format';
                        }
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _errorMsg = null);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'isActive': _isActive,
    };

    if (_isPolygonMode) {
      data['polygonGeo'] = jsonDecode(_geoJsonCtrl.text);
      data['maxDistanceKm'] = null; // Clear radius if polygon
    } else {
      data['maxDistanceKm'] = double.parse(_radiusCtrl.text);
      data['polygonGeo'] = null; // Clear polygon if radius
    }

    try {
      if (widget.zone == null) {
        await ref.read(zonesProvider.notifier).createZone(data);
      } else {
        await ref.read(zonesProvider.notifier).updateZone(widget.zone!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    }
  }
}

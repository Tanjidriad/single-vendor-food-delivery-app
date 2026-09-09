import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../data/addresses_repository.dart';
import '../providers/addresses_providers.dart';
import '../../../../core/widgets/map/app_map_view.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import 'package:geolocator/geolocator.dart';

class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key, this.editAddress});

  final Map<String, dynamic>? editAddress;

  @override
  ConsumerState<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController(text: 'Dhaka');
  final _postalController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _label = 'HOME';
  double? _geocodedLat;
  double? _geocodedLng;
  bool _isDefault = true;
  bool _geocoding = false;
  bool _saving = false;

  bool get _isEdit => widget.editAddress != null;

  @override
  void initState() {
    super.initState();
    final a = widget.editAddress;
    if (a != null) {
      _label = a['label'] as String? ?? 'HOME';
      _line1Controller.text = a['line1'] as String? ?? '';
      _line2Controller.text = a['line2'] as String? ?? '';
      _cityController.text = a['city'] as String? ?? 'Dhaka';
      _postalController.text = a['postalCode'] as String? ?? '';
      _instructionsController.text = a['instructions'] as String? ?? '';
      _isDefault = a['isDefault'] == true;
      _geocodedLat = _parseCoord(a['latitude']?.toString());
      _geocodedLng = _parseCoord(a['longitude']?.toString());
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  double? _parseCoord(String? text) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _geocode() async {
    final query = '${_line1Controller.text.trim()}, ${_cityController.text.trim()}';
    if (query.length < 5) {
      AppLoaders.warningSnackBar(
        context,
        title: 'Address too short',
        message: 'Enter street and city first to find coordinates.',
      );
      return;
    }

    setState(() => _geocoding = true);
    try {
      final result = await ref.read(addressesRepositoryProvider).geocode(query);
      final lat = _parseCoord(result['latitude']?.toString());
      final lng = _parseCoord(result['longitude']?.toString());
      setState(() {
        _geocodedLat = lat;
        _geocodedLng = lng;
      });
      if (mounted && lat != null && lng != null) {
        AppLoaders.successSnackBar(
          context,
          title: 'Location found',
          message: 'Coordinates successfully mapped.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.warningSnackBar(
          context,
          title: 'Map lookup unavailable',
          message:
              'Could not fetch coordinates. Enter the address more precisely or use current location.',
        );
        setState(() {
          _geocodedLat = null;
          _geocodedLng = null;
        });
      }
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _geocoding = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      setState(() {
        _geocodedLat = position.latitude;
        _geocodedLng = position.longitude;
      });
      
      if (mounted) {
        AppLoaders.successSnackBar(
          context,
          title: 'Location found',
          message: 'GPS Coordinates successfully mapped.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.warningSnackBar(
          context,
          title: 'Location Error',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_geocodedLat == null || _geocodedLng == null) {
      await _geocode();
      if (_geocodedLat == null || _geocodedLng == null) return;
    }

    setState(() => _saving = true);
    final body = {
      'label': _label,
      'line1': _line1Controller.text.trim(),
      if (_line2Controller.text.trim().isNotEmpty) 'line2': _line2Controller.text.trim(),
      'city': _cityController.text.trim(),
      if (_postalController.text.trim().isNotEmpty) 'postalCode': _postalController.text.trim(),
      'latitude': _geocodedLat,
      'longitude': _geocodedLng,
      if (_instructionsController.text.trim().isNotEmpty) 'instructions': _instructionsController.text.trim(),
      'isDefault': _isDefault,
    };
    try {
      if (_isEdit) {
        await ref.read(addressesRepositoryProvider).update(widget.editAddress!['id'] as String, body);
      } else {
        await ref.read(addressesRepositoryProvider).create(body);
      }
      ref.invalidate(addressesListProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(context, title: 'Could not save address', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildLabelPill(String label, IconData icon) {
    final isSelected = _label == label;
    return GestureDetector(
      onTap: () => setState(() => _label = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = AppHelperFunctions.isDarkMode(context);

    final restaurant = ref.watch(restaurantProvider).valueOrNull;
    final zones = (restaurant?['deliveryZones'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    final restLat = (restaurant?['latitude'] as num?)?.toDouble();
    final restLng = (restaurant?['longitude'] as num?)?.toDouble();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Static Map Header Placeholder
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _geocodedLat != null && _geocodedLng != null
                      ? AppMapView(
                          initialLatitude: _geocodedLat!,
                          initialLongitude: _geocodedLng!,
                          markers: const [],
                          fitMarkersInView: false,
                          zones: zones,
                          restaurantLatitude: restLat,
                          restaurantLongitude: restLng,
                        )
                      : ColoredBox(
                          color: isDark
                              ? const Color(0xFF1F2937)
                              : AppColors.gray100,
                          child: Center(
                            child: Text(
                              'Find location or use GPS to preview the map',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.gray500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              ),
              // Map Pin
              const Icon(Icons.location_on, size: 48, color: AppColors.primary),
              // Close Button
              Positioned(
                top: 16,
                left: 16,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ],
          ),

          // Scrollable Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery details', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Address Line 1 with Locate Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _line1Controller,
                            label: 'Street address *',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _geocoding ? null : _fetchCurrentLocation,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: _geocoding 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                : const Icon(Icons.my_location, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    if (_geocodedLat != null && _geocodedLng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                            const SizedBox(width: 6),
                            Text('Location found on map', style: textTheme.labelSmall?.copyWith(color: AppColors.success)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Floor / Unit
                    AppTextField(
                      controller: _line2Controller,
                      label: 'Floor / Unit (Optional)',
                    ),
                    const SizedBox(height: 16),

                    // City and Postal Row
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _cityController,
                            label: 'City *',
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _postalController,
                            label: 'Postal code (Optional)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Note to Rider
                    AppTextField(
                      controller: _instructionsController,
                      label: 'Note to rider (Optional)',
                      hint: 'e.g. Please leave at the door',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Save As Labels
                    Text('Save as', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLabelPill('HOME', Icons.home_outlined),
                          _buildLabelPill('OFFICE', Icons.work_outline),
                          _buildLabelPill('PARTNER', Icons.favorite_border),
                          _buildLabelPill('OTHER', Icons.location_on_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Default Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Set as default address', style: textTheme.bodyLarge),
                      value: _isDefault,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isDefault = v),
                    ),
                    
                    // Bottom padding for keyboard
                    SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 20),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Bottom Save Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 10),
              ],
            ),
            child: AppButton(
              label: _isEdit ? 'Update Address' : 'Save Address',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

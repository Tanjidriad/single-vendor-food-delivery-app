import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/map/app_map_view.dart';
import '../../../../core/widgets/map/models/app_map_marker.dart';
import '../utils/checkout_format.dart';

/// Delivery-address card on the checkout screen: a small map preview, the
/// selected address (or an add-address prompt), and a delivery-instructions
/// field.
class CheckoutAddressCard extends StatelessWidget {
  const CheckoutAddressCard({
    super.key,
    required this.address,
    required this.instructionsController,
    required this.onSelectAddress,
  });

  /// The selected delivery address, or null when none is chosen yet.
  final Map<String, dynamic>? address;
  final TextEditingController instructionsController;
  final VoidCallback onSelectAddress;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null;
    final lat = hasAddress ? coord(address!['latitude']) : null;
    final lng = hasAddress ? coord(address!['longitude']) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasAddress && lat != null && lng != null
                    ? AppMapView(
                        initialLatitude: lat,
                        initialLongitude: lng,
                        markers: [
                          AppMapMarker(id: 'dest', latitude: lat, longitude: lng),
                        ],
                      )
                    : Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(
                          Icons.add_location_alt,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAddress
                          ? (address!['label'] as String? ?? 'Delivery')
                          : 'No address selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAddress
                          ? formatAddressLine(address!)
                          : 'Add an address for delivery',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!hasAddress)
                TextButton(
                  onPressed: onSelectAddress,
                  child: const Text(
                    'Add Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  onPressed: onSelectAddress,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                controller: instructionsController,
                maxLength: 500,
                maxLines: 3,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '(Optional) Floor or Apt No or tell us ...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
              Positioned(
                left: 12,
                top: -8,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: const Text(
                    'Delivery instructions',
                    style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

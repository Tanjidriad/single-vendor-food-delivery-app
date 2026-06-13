import 'package:flutter/material.dart';

import '../../../features/media/presentation/screens/media_management_screen.dart';
import '../../theme/app_colors.dart';

class MediaPickerWidget extends StatelessWidget {
  final String? currentImageUrl;
  final Function(String url) onImageSelected;
  final String label;

  const MediaPickerWidget({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.label = 'Select Image',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MediaManagementScreen(
                      isDialog: true,
                      onImageSelected: onImageSelected,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.background,
              image: currentImageUrl != null && currentImageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(currentImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: currentImageUrl == null || currentImageUrl!.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click to choose from Media Library',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'shimmer.dart';

class TMenuItemShimmer extends StatelessWidget {
  const TMenuItemShimmer({
    super.key,
    this.itemCount = 4,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Shimmer
              const TShimmerEffect(width: 80, height: 80, radius: 12),
              const SizedBox(width: 12),
              // Text Content Shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const TShimmerEffect(width: 160, height: 16),
                    const SizedBox(height: 8),
                    const TShimmerEffect(width: double.infinity, height: 12),
                    const SizedBox(height: 4),
                    const TShimmerEffect(width: double.infinity, height: 12),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        TShimmerEffect(width: 60, height: 20),
                        TShimmerEffect(width: 32, height: 32, radius: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

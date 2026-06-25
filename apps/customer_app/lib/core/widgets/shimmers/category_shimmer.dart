import 'package:flutter/material.dart';
import 'shimmer.dart';

class TCategoryShimmer extends StatelessWidget {
  const TCategoryShimmer({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: itemCount,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, _) {
          return const TShimmerEffect(width: 100, height: 40, radius: 12);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CwtLoginHeader extends StatelessWidget {
  const CwtLoginHeader({
    super.key,
    this.title = 'Welcome to WASABI',
    this.subtitle = 'Discover the best food around you.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image(
          height: 150,
          image: AssetImage(dark ? 'assets/logos/t-store-splash-logo-white.png' : 'assets/logos/t-store-splash-logo-black.png'),
        ),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class CwtFormDivider extends StatelessWidget {
  const CwtFormDivider({super.key, required this.dividerText});

  final String dividerText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Divider(color: Colors.grey.withValues(alpha: 0.5), thickness: 0.5, indent: 60, endIndent: 5)),
        Text(dividerText, style: Theme.of(context).textTheme.labelMedium),
        Flexible(child: Divider(color: Colors.grey.withValues(alpha: 0.5), thickness: 0.5, indent: 5, endIndent: 60)),
      ],
    );
  }
}


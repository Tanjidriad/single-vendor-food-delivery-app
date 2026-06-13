import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';

class CwtUserProfileTile extends ConsumerWidget {
  const CwtUserProfileTile({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final initial = (user?.fullName ?? user?.email ?? 'U').substring(0, 1).toUpperCase();

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        child: Text(
          initial,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
        ),
      ),
      title: Text(
        user?.fullName ?? 'User',
        style: Theme.of(context).textTheme.headlineSmall?.apply(color: Colors.white),
      ),
      subtitle: Text(
        user?.email ?? '',
        style: Theme.of(context).textTheme.bodyMedium?.apply(color: Colors.white),
      ),
      trailing: IconButton(
        onPressed: onPressed,
        icon: const Icon(Iconsax.edit, color: Colors.white),
      ),
    );
  }
}

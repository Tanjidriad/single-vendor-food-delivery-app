import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/addresses_repository.dart';

final addressesListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(addressesRepositoryProvider).list();
});

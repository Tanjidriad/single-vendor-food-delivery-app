import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAutoPrint = 'kitchen_auto_print';
const _kSoundEnabled = 'kitchen_sound_enabled';
const _kShowTestOrders = 'kitchen_show_test_orders';

class KitchenPreferences {
  const KitchenPreferences({
    required this.autoPrint,
    required this.soundEnabled,
    required this.showTestOrders,
  });

  final bool autoPrint;
  final bool soundEnabled;
  final bool showTestOrders;

  KitchenPreferences copyWith({
    bool? autoPrint,
    bool? soundEnabled,
    bool? showTestOrders,
  }) {
    return KitchenPreferences(
      autoPrint: autoPrint ?? this.autoPrint,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showTestOrders: showTestOrders ?? this.showTestOrders,
    );
  }
}

final kitchenPreferencesProvider =
    NotifierProvider<KitchenPreferencesNotifier, KitchenPreferences>(
  KitchenPreferencesNotifier.new,
);

class KitchenPreferencesNotifier extends Notifier<KitchenPreferences> {
  SharedPreferences? _prefs;

  @override
  KitchenPreferences build() {
    Future.microtask(_load);
    return const KitchenPreferences(
      autoPrint: true,
      soundEnabled: true,
      showTestOrders: false,
    );
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    final prefs = await _ensurePrefs();
    state = KitchenPreferences(
      autoPrint: prefs.getBool(_kAutoPrint) ?? true,
      soundEnabled: prefs.getBool(_kSoundEnabled) ?? true,
      showTestOrders: prefs.getBool(_kShowTestOrders) ?? false,
    );
  }

  Future<void> setAutoPrint(bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_kAutoPrint, value);
    state = state.copyWith(autoPrint: value);
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_kSoundEnabled, value);
    state = state.copyWith(soundEnabled: value);
  }

  Future<void> setShowTestOrders(bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_kShowTestOrders, value);
    state = state.copyWith(showTestOrders: value);
  }
}

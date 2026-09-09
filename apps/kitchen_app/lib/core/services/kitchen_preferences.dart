import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAutoPrint = 'kitchen_auto_print';
const _kSoundEnabled = 'kitchen_sound_enabled';
const _kShowTestOrders = 'kitchen_show_test_orders';
const _kThemeMode = 'kitchen_theme_mode';
const _kCompactDensity = 'kitchen_compact_density';
const _kClosingPin = 'kitchen_closing_pin';

class KitchenPreferences {
  const KitchenPreferences({
    required this.autoPrint,
    required this.soundEnabled,
    required this.showTestOrders,
    required this.themeMode,
    required this.compactDensity,
    required this.closingPin,
  });

  final bool autoPrint;
  final bool soundEnabled;
  final bool showTestOrders;
  final ThemeMode themeMode;
  final bool compactDensity;
  /// 4-digit PIN required to close the restaurant. Empty string = no PIN set.
  final String closingPin;

  bool get hasPinSet => closingPin.isNotEmpty;

  KitchenPreferences copyWith({
    bool? autoPrint,
    bool? soundEnabled,
    bool? showTestOrders,
    ThemeMode? themeMode,
    bool? compactDensity,
    String? closingPin,
  }) {
    return KitchenPreferences(
      autoPrint: autoPrint ?? this.autoPrint,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showTestOrders: showTestOrders ?? this.showTestOrders,
      themeMode: themeMode ?? this.themeMode,
      compactDensity: compactDensity ?? this.compactDensity,
      closingPin: closingPin ?? this.closingPin,
    );
  }
}

final kitchenPreferencesProvider =
    NotifierProvider<KitchenPreferencesNotifier, KitchenPreferences>(
  KitchenPreferencesNotifier.new,
);

class KitchenPreferencesNotifier extends Notifier<KitchenPreferences> {
  SharedPreferences? _prefs;
  static const _secureStorage = FlutterSecureStorage();

  @override
  KitchenPreferences build() {
    Future.microtask(_load);
    return const KitchenPreferences(
      autoPrint: true,
      soundEnabled: true,
      showTestOrders: false,
      themeMode: ThemeMode.system,
      compactDensity: false,
      closingPin: '',
    );
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    final prefs = await _ensurePrefs();
    final pin = await _secureStorage.read(key: _kClosingPin) ??
        prefs.getString(_kClosingPin) ??
        '';
    if (prefs.containsKey(_kClosingPin)) {
      await _secureStorage.write(key: _kClosingPin, value: pin);
      await prefs.remove(_kClosingPin);
    }
    state = KitchenPreferences(
      autoPrint: prefs.getBool(_kAutoPrint) ?? true,
      soundEnabled: prefs.getBool(_kSoundEnabled) ?? true,
      showTestOrders: prefs.getBool(_kShowTestOrders) ?? false,
      themeMode: _parseThemeMode(prefs.getString(_kThemeMode)),
      compactDensity: prefs.getBool(_kCompactDensity) ?? false,
      closingPin: pin,
    );
  }

  ThemeMode _parseThemeMode(String? value) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
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

  Future<void> setThemeMode(ThemeMode value) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_kThemeMode, value.name);
    state = state.copyWith(themeMode: value);
  }

  Future<void> setCompactDensity(bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_kCompactDensity, value);
    state = state.copyWith(compactDensity: value);
  }

  Future<void> setClosingPin(String pin) async {
    await _secureStorage.write(key: _kClosingPin, value: pin);
    state = state.copyWith(closingPin: pin);
  }

  Future<void> clearClosingPin() async {
    await _secureStorage.delete(key: _kClosingPin);
    state = state.copyWith(closingPin: '');
  }
}

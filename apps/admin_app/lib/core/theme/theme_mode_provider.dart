import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key under which the selected [ThemeMode] is persisted.
const String kThemeModePreferenceKey = 'theme_mode';

const String _lightValue = 'light';
const String _darkValue = 'dark';

/// Decodes a stored preference string into a [ThemeMode].
///
/// Returns [ThemeMode.light] when the value is absent or unrecognised,
/// satisfying the requirement to default to light when no preference is
/// stored (Requirement 18.4).
ThemeMode decodeThemeMode(String? value) {
  switch (value) {
    case _darkValue:
      return ThemeMode.dark;
    case _lightValue:
      return ThemeMode.light;
    default:
      return ThemeMode.light;
  }
}

/// Encodes a [ThemeMode] into the string persisted in SharedPreferences.
String encodeThemeMode(ThemeMode mode) {
  return mode == ThemeMode.dark ? _darkValue : _lightValue;
}

/// Reads the persisted [ThemeMode] directly from local storage.
///
/// Intended to be awaited during application start-up (in `main()`) so the
/// stored theme can be applied before the first visible frame is rendered
/// (Requirement 18.6). Defaults to [ThemeMode.light] when no preference has
/// been stored (Requirement 18.4).
Future<ThemeMode> readStoredThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return decodeThemeMode(prefs.getString(kThemeModePreferenceKey));
}

/// Manages the active [ThemeMode] for the admin panel and persists the user's
/// preference to local storage.
///
/// The notifier loads any stored preference on initialisation and exposes a
/// [toggle] method that switches between light and dark and persists the new
/// value (Requirements 18.3, 18.4, 18.6).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  SharedPreferences? _prefs;

  @override
  ThemeMode build() {
    // Default to light immediately so the first frame has a valid theme
    // (Requirement 18.4), then asynchronously hydrate from local storage.
    _loadFromStorage();
    return ThemeMode.light;
  }

  Future<void> _loadFromStorage() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final stored = decodeThemeMode(prefs.getString(kThemeModePreferenceKey));
    if (stored != state) {
      state = stored;
    }
  }

  /// Switches between light and dark mode and persists the new preference.
  ///
  /// The state is updated synchronously so the new theme is applied within the
  /// same frame (Requirement 18.3); persistence happens afterwards.
  Future<void> toggle() async {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    await _persist(next);
  }

  /// Explicitly sets the [ThemeMode] and persists the preference.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) {
      return;
    }
    state = mode;
    await _persist(mode);
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(kThemeModePreferenceKey, encodeThemeMode(mode));
  }
}

/// Provider exposing the active [ThemeMode] and its [ThemeModeNotifier].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

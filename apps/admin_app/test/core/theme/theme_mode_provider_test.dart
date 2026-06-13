import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin_app/core/theme/theme_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeThemeMode', () {
    test('returns light when value is null (no stored preference)', () {
      // Requirement 18.4: default to light when nothing is stored.
      expect(decodeThemeMode(null), ThemeMode.light);
    });

    test('returns light for unrecognised values', () {
      expect(decodeThemeMode('bogus'), ThemeMode.light);
    });

    test('returns dark for the dark value', () {
      expect(decodeThemeMode('dark'), ThemeMode.dark);
    });

    test('returns light for the light value', () {
      expect(decodeThemeMode('light'), ThemeMode.light);
    });
  });

  group('encodeThemeMode round-trip', () {
    test('encode then decode preserves the mode', () {
      expect(decodeThemeMode(encodeThemeMode(ThemeMode.light)), ThemeMode.light);
      expect(decodeThemeMode(encodeThemeMode(ThemeMode.dark)), ThemeMode.dark);
    });
  });

  group('readStoredThemeMode', () {
    test('defaults to light when storage is empty', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await readStoredThemeMode(), ThemeMode.light);
    });

    test('returns the previously stored preference', () async {
      // Requirement 18.6: stored theme is available before first frame.
      SharedPreferences.setMockInitialValues({
        kThemeModePreferenceKey: 'dark',
      });
      expect(await readStoredThemeMode(), ThemeMode.dark);
    });
  });

  group('ThemeModeNotifier', () {
    test('initial state is light when no preference is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('hydrates dark from stored preference after init', () async {
      SharedPreferences.setMockInitialValues({
        kThemeModePreferenceKey: 'dark',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger build, then allow the async load to complete.
      expect(container.read(themeModeProvider), ThemeMode.light);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggle switches mode and persists the new value', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Requirement 18.3: preference is persisted to local storage.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kThemeModePreferenceKey), 'dark');

      await notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString(kThemeModePreferenceKey), 'light');
    });

    test('setThemeMode updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kThemeModePreferenceKey), 'dark');
    });
  });
}

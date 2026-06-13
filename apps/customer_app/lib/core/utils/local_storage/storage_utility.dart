import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local preferences (tokens use [FlutterSecureStorage] in auth).
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> writeString(String key, String value) => _prefs.setString(key, value);

  String? readString(String key) => _prefs.getString(key);

  Future<bool> writeBool(String key, bool value) => _prefs.setBool(key, value);

  bool? readBool(String key) => _prefs.getBool(key);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override sharedPreferencesProvider in main() after init',
  );
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

typedef TLocalStorage = LocalStorage;

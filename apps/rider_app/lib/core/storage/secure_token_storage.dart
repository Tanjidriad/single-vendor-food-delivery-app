import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _accessKey = 'jwt_token';
const _refreshKey = 'jwt_refresh_token';
const _migratedKey = 'tokens_migrated_to_secure_storage';

/// Persists auth tokens in encrypted storage (migrates legacy SharedPreferences once).
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? secure})
      : _secure = secure ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _secure;
  bool _migrationDone = false;

  Future<void> _migrateFromPrefsIfNeeded() async {
    if (_migrationDone) return;
    _migrationDone = true;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final legacyAccess = prefs.getString(_accessKey);
    final legacyRefresh = prefs.getString(_refreshKey);
    if (legacyAccess != null && legacyAccess.isNotEmpty) {
      await _secure.write(key: _accessKey, value: legacyAccess);
    }
    if (legacyRefresh != null && legacyRefresh.isNotEmpty) {
      await _secure.write(key: _refreshKey, value: legacyRefresh);
    }

    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.setBool(_migratedKey, true);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _migrateFromPrefsIfNeeded();
    await _secure.write(key: _accessKey, value: accessToken);
    await _secure.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> readAccessToken() async {
    await _migrateFromPrefsIfNeeded();
    return _secure.read(key: _accessKey);
  }

  Future<String?> readRefreshToken() async {
    await _migrateFromPrefsIfNeeded();
    return _secure.read(key: _refreshKey);
  }

  Future<void> clear() async {
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central service for persisting user preferences and secure credentials.
class UserPreferencesService {
  const UserPreferencesService._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys
  static const _keyTheme = 'user_theme_feminine';
  static const _keyRemember = 'remember_login_enabled';
  static const _keyEmail = 'remembered_login_email';
  static const _keyPassword = 'remembered_login_password';

  // ── Theme ──────────────────────────────────────────────────────────────────
  static Future<bool> loadFeminineTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ?? false;
  }

  static Future<void> saveFeminineTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, value);
  }

  // ── Login credentials ──────────────────────────────────────────────────────
  static Future<({bool remember, String email, String password})>
      loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    if (!remember) return (remember: false, email: '', password: '');
    final email = prefs.getString(_keyEmail) ?? '';
    final password = await _secure.read(key: _keyPassword) ?? '';
    return (remember: true, email: email, password: password);
  }

  static Future<void> saveCredentials({
    required bool remember,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keyEmail, email.trim());
      await _secure.write(key: _keyPassword, value: password);
    } else {
      await prefs.setBool(_keyRemember, false);
      await prefs.remove(_keyEmail);
      await _secure.delete(key: _keyPassword);
    }
  }
}

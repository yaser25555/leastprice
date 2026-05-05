import 'package:shared_preferences/shared_preferences.dart';

/// Central service for persisting user preferences.
///
/// Note: Passwords are **never** stored locally. Firebase Auth handles session
/// persistence automatically.
class UserPreferencesService {
  const UserPreferencesService._();

  // Keys
  static const _keyTheme = 'user_theme_feminine';
  static const _keyRemember = 'remember_login_enabled';
  static const _keyEmail = 'remembered_login_email';

  // ── Theme ──────────────────────────────────────────────────────────────────
  static Future<bool> loadFeminineTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ?? false;
  }

  static Future<void> saveFeminineTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, value);
  }

  // ── Login credentials (email only — passwords are never stored) ────────────
  static Future<({bool remember, String email})> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    if (!remember) return (remember: false, email: '');
    final email = prefs.getString(_keyEmail) ?? '';
    return (remember: true, email: email);
  }

  static Future<void> saveCredentials({
    required bool remember,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keyEmail, email.trim());
    } else {
      await prefs.setBool(_keyRemember, false);
      await prefs.remove(_keyEmail);
    }
  }
}


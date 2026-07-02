import 'package:shared_preferences/shared_preferences.dart';

// يدير حالة الجلسة بعد تسجيل الدخول الناجح
class SessionService {
  static const _keyUserId = 'session_user_id';
  static const _keyUserName = 'session_user_name';
  static const _keyUserRole = 'session_user_role';
  static const _keyRemember = 'session_remember';

  Future<void> saveSession({
    required int userId,
    required String fullName,
    required String role,
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserName, fullName);
    await prefs.setString(_keyUserRole, role);
    await prefs.setBool(_keyRemember, remember);
  }

  Future<Map<String, dynamic>?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    if (!remember) return null;

    final userId = prefs.getInt(_keyUserId);
    if (userId == null) return null;

    return {
      'userId': userId,
      'fullName': prefs.getString(_keyUserName) ?? '',
      'role': prefs.getString(_keyUserRole) ?? '',
    };
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

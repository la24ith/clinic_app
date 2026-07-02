import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  // تشفير كلمة المرور - نستخدمها عند:
  // 1. إنشاء مستخدم جديد (نخزن الـ Hash)
  // 2. تسجيل الدخول (نقارن Hash المُدخل بالمخزون)
  static String hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static bool verify(String plainPassword, String storedHash) {
    return hash(plainPassword) == storedHash;
  }
}

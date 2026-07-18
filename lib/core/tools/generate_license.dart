// أداة سطر أوامر تشغلها أنت لما يشتري أحد
// lib/tools/generate_license.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';

void main(List<String> args) {
  // مثال: dart run lib/tools/generate_license.dart HW123456 365
  final hardwareId = args[0]; // معرف جهاز العميل
  final days = int.parse(args[1]); // مدة الاشتراك بالأيام

  final expiry = DateTime.now().add(Duration(days: days));
  final expiryStr = expiry.millisecondsSinceEpoch.toString();

  // بيانات الـ License
  final data = '$hardwareId:$expiryStr';

  // توقيع سري (Secret Key تحتفظ به أنت فقط)
  const secret = 'YOUR_SECRET_KEY_CHANGE_THIS_2024';
  final hmac = Hmac(sha256, utf8.encode(secret));
  final sig = hmac.convert(utf8.encode(data)).toString().substring(0, 8);

  // تشفير البيانات
  final encoded = base64Url.encode(utf8.encode(data)).replaceAll('=', '');

  // تنسيق الـ Key
  final raw = '$encoded$sig'.toUpperCase();
  final key = 'CLINIC-${_chunk(raw)}';

  print('Hardware ID : $hardwareId');
  print('Expires     : $expiry');
  print('License Key : $key');
}

String _chunk(String s) {
  final clean = s.replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final parts = <String>[];
  for (int i = 0; i < clean.length && parts.length < 4; i += 4) {
    final end = (i + 4 < clean.length) ? i + 4 : clean.length;
    parts.add(clean.substring(i, end));
  }
  return parts.join('-');
}

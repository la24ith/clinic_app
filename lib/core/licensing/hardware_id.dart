// lib/core/licensing/hardware_id.dart
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class HardwareId {
  static Future<String> get() async {
    try {
      // على ويندوز: نستخدم معرف المعالج + اسم الجهاز
      final result = await Process.run('wmic', [
        'cpu',
        'get',
        'ProcessorId',
      ], stdoutEncoding: const SystemEncoding());
      final cpuId = result.stdout
          .toString()
          .replaceAll('ProcessorId', '')
          .trim();

      final machineName = Platform.localHostname;
      final combined = '$cpuId-$machineName';

      // نشفره لنحصل على معرف ثابت قصير
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);
      return digest.toString().substring(0, 16).toUpperCase();
    } catch (e) {
      // Fallback: اسم الجهاز فقط
      final bytes = utf8.encode(Platform.localHostname);
      final digest = sha256.convert(bytes);
      return digest.toString().substring(0, 16).toUpperCase();
    }
  }
}

// lib/core/licensing/license_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'hardware_id.dart';

enum LicenseStatus {
  trial, // فترة تجريبية
  trialExpired, // انتهت الفترة التجريبية
  active, // مرخص وفعال
  expired, // انتهى الترخيص
  invalid, // ترخيص غير صالح
}

class LicenseInfo {
  final LicenseStatus status;
  final int daysRemaining;
  final DateTime? expiryDate;
  final bool isTrial;

  const LicenseInfo({
    required this.status,
    required this.daysRemaining,
    this.expiryDate,
    this.isTrial = false,
  });
}

class LicenseManager {
  static const _secret = 'YOUR_SECRET_KEY_CHANGE_THIS_2024';
  static const _trialDays = 30;
  static const _licenseFile = 'clinic_license.dat';
  static const _trialFile = 'clinic_trial.dat';

  // التحقق الكامل من حالة الترخيص
  static Future<LicenseInfo> check() async {
    // 1. هل في License Key مسجل؟
    final license = await _loadLicense();
    if (license != null) {
      return await _validateLicense(license);
    }

    // 2. لا يوجد License → تحقق من الفترة التجريبية
    return await _checkTrial();
  }

  // التحقق من الفترة التجريبية
  static Future<LicenseInfo> _checkTrial() async {
    final trialStart = await _getOrCreateTrialStart();
    final now = DateTime.now();
    final elapsed = now.difference(trialStart).inDays;
    final remaining = _trialDays - elapsed;

    if (remaining > 0) {
      return LicenseInfo(
        status: LicenseStatus.trial,
        daysRemaining: remaining,
        expiryDate: trialStart.add(const Duration(days: _trialDays)),
        isTrial: true,
      );
    }

    return const LicenseInfo(
      status: LicenseStatus.trialExpired,
      daysRemaining: 0,
      isTrial: true,
    );
  }

  // التحقق من الـ License Key
  static Future<LicenseInfo> _validateLicense(String key) async {
    try {
      final hwId = await HardwareId.get();

      // فك تشفير الـ Key
      final clean = key
          .replaceAll('CLINIC-', '')
          .replaceAll('-', '')
          .toUpperCase();

      if (clean.length < 8) {
        return const LicenseInfo(
          status: LicenseStatus.invalid,
          daysRemaining: 0,
        );
      }

      final sig = clean.substring(clean.length - 8);
      final encoded = clean.substring(0, clean.length - 8);

      // فك التشفير
      final padding = encoded.length % 4;
      final padded = padding > 0 ? encoded + ('=' * (4 - padding)) : encoded;
      final data = utf8.decode(base64Url.decode(padded));
      final parts = data.split(':');

      if (parts.length != 2) {
        return const LicenseInfo(
          status: LicenseStatus.invalid,
          daysRemaining: 0,
        );
      }

      final licenseHwId = parts[0];
      final expiryMs = int.parse(parts[1]);
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);

      // التحقق من التوقيع
      final hmac = Hmac(sha256, utf8.encode(_secret));
      final expectedSig = hmac
          .convert(utf8.encode(data))
          .toString()
          .substring(0, 8)
          .toUpperCase();

      if (sig != expectedSig) {
        return const LicenseInfo(
          status: LicenseStatus.invalid,
          daysRemaining: 0,
        );
      }

      // التحقق من معرف الجهاز
      if (licenseHwId != hwId) {
        return const LicenseInfo(
          status: LicenseStatus.invalid,
          daysRemaining: 0,
        );
      }

      // التحقق من تاريخ الانتهاء
      final now = DateTime.now();
      final remaining = expiry.difference(now).inDays;

      if (remaining < 0) {
        return LicenseInfo(
          status: LicenseStatus.expired,
          daysRemaining: 0,
          expiryDate: expiry,
        );
      }

      return LicenseInfo(
        status: LicenseStatus.active,
        daysRemaining: remaining,
        expiryDate: expiry,
      );
    } catch (e) {
      return const LicenseInfo(status: LicenseStatus.invalid, daysRemaining: 0);
    }
  }

  // تسجيل License Key جديد
  static Future<LicenseInfo> activate(String key) async {
    final info = await _validateLicense(key.trim().toUpperCase());
    if (info.status == LicenseStatus.active) {
      await _saveLicense(key.trim().toUpperCase());
    }
    return info;
  }

  // ── ملفات محلية ──
  static Future<DateTime> _getOrCreateTrialStart() async {
    final file = await _getFile(_trialFile);
    if (await file.exists()) {
      final ms = int.parse(await file.readAsString());
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final now = DateTime.now();
    await file.writeAsString(now.millisecondsSinceEpoch.toString());
    return now;
  }

  static Future<String?> _loadLicense() async {
    final file = await _getFile(_licenseFile);
    if (await file.exists()) {
      return (await file.readAsString()).trim();
    }
    return null;
  }

  static Future<void> _saveLicense(String key) async {
    final file = await _getFile(_licenseFile);
    await file.writeAsString(key);
  }

  static Future<File> _getFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, name));
  }

  // معرف الجهاز للعرض للمستخدم
  static Future<String> getHardwareId() => HardwareId.get();
}

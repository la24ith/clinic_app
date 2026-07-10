import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/database.dart';
import 'prescription_service.dart';

class WhatsAppService {
  /// المدخل الرئيسي — يختار التنفيذ حسب المنصة
  static Future<WhatsAppResult> sharePresciption({
    required Visit visit,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    try {
      // 1. توليد الـ PDF
      final pdfBytes = await _generatePdfBytes(
        visit: visit,
        patient: patient,
        setting: setting,
      );

      // 2. حفظ الـ PDF مؤقتاً
      final file = await _saveTempPdf(
        bytes: pdfBytes,
        patientName: patient.fullName,
        visitDate: visit.visitDate,
      );

      // 3. تنفيذ المشاركة حسب المنصة
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return await _shareOnDesktop(
          file: file,
          patient: patient,
          setting: setting,
        );
      } else {
        // موبايل (Android/iOS) — لاحقاً
        return await _shareOnMobile(
          file: file,
          patient: patient,
          setting: setting,
        );
      }
    } catch (e) {
      return WhatsAppResult.failure('فشل المشاركة: $e');
    }
  }

  // ── Desktop: حفظ + فتح واتساب ويب ──
  static Future<WhatsAppResult> _shareOnDesktop({
    required File file,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    // تنظيف رقم الهاتف (إزالة الفراغات والرموز)
    final phone = _cleanPhone(patient.phone);

    // رسالة واتساب جاهزة
    final doctorName = setting.doctorName ?? 'الطبيب';
    final message =
        'السلام عليكم ${patient.fullName}،\n'
        'تجدون مرفقاً الوصفة الطبية من $doctorName.\n'
        'تاريخ الزيارة: ${_formatDate(file.path)}';

    // فتح واتساب ويب
    final whatsappUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(
      whatsappUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      return WhatsAppResult.failure(
        'تعذر فتح واتساب. تأكد من تثبيت واتساب أو استخدام واتساب ويب.',
      );
    }

    return WhatsAppResult.desktopSuccess(
      pdfPath: file.path,
      message: 'تم فتح واتساب\nيرجى إرفاق الوصفة يدوياً من:\n${file.path}',
    );
  }

  // ── Mobile: مشاركة مباشرة مع PDF ──
  static Future<WhatsAppResult> _shareOnMobile({
    required File file,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    final doctorName = setting.doctorName ?? 'الطبيب';
    final message =
        'السلام عليكم ${patient.fullName}،\n'
        'تجدون مرفقاً الوصفة الطبية من $doctorName.';

    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: message,
      subject: 'وصفة طبية - ${patient.fullName}',
    );

    if (result.status == ShareResultStatus.success) {
      return WhatsAppResult.mobileSuccess();
    } else if (result.status == ShareResultStatus.dismissed) {
      return WhatsAppResult.cancelled();
    }

    return WhatsAppResult.failure('لم تكتمل المشاركة');
  }

  // ── توليد بايتات الـ PDF ──
  static Future<List<int>> _generatePdfBytes({
    required Visit visit,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    final pdf = await PrescriptionService.buildPdfDocument(
      visit: visit,
      patient: patient,
      setting: setting,
    );
    return pdf.save();
  }

  // ── حفظ PDF مؤقتاً ──
  static Future<File> _saveTempPdf({
    required List<int> bytes,
    required String patientName,
    required DateTime visitDate,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = patientName.replaceAll(' ', '_');
    final dateStr = '${visitDate.day}-${visitDate.month}-${visitDate.year}';
    final fileName = 'وصفة_${safeName}_$dateStr.pdf';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── تنظيف رقم الهاتف ──
  static String _cleanPhone(String phone) {
    // إزالة كل شيء إلا الأرقام و +
    var cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // إضافة كود سوريا إذا لم يكن موجوداً
    if (cleaned.startsWith('0')) {
      cleaned = '+963${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+963$cleaned';
    }
    return cleaned;
  }

  static String _formatDate(String path) {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

// ── نتيجة المشاركة ──
class WhatsAppResult {
  final bool isSuccess;
  final bool isCancelled;
  final bool isDesktop;
  final String? message;
  final String? pdfPath;
  final String? error;

  const WhatsAppResult._({
    required this.isSuccess,
    this.isCancelled = false,
    this.isDesktop = false,
    this.message,
    this.pdfPath,
    this.error,
  });

  factory WhatsAppResult.desktopSuccess({
    required String pdfPath,
    required String message,
  }) => WhatsAppResult._(
    isSuccess: true,
    isDesktop: true,
    pdfPath: pdfPath,
    message: message,
  );

  factory WhatsAppResult.mobileSuccess() =>
      const WhatsAppResult._(isSuccess: true);

  factory WhatsAppResult.cancelled() =>
      const WhatsAppResult._(isSuccess: false, isCancelled: true);

  factory WhatsAppResult.failure(String error) =>
      WhatsAppResult._(isSuccess: false, error: error);
}

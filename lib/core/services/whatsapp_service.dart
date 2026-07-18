import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/database.dart';
import 'prescription_service.dart';

class WhatsAppService {
  static Future<WhatsAppResult> sharePresciption({
    required Visit visit,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    try {
      final pdfBytes = await _generatePdfBytes(
        visit: visit,
        patient: patient,
        setting: setting,
      );

      final file = await _saveTempPdf(
        bytes: pdfBytes,
        patientName: patient.fullName,
        visitDate: visit.visitDate,
      );

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return await _shareOnDesktop(
          file: file,
          patient: patient,
          setting: setting,
        );
      } else {
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

  static Future<WhatsAppResult> _shareOnDesktop({
    required File file,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    final phone = _cleanPhone(patient.phone);
    final doctorName = setting.doctorName ?? 'الطبيب';

    final message =
        'السلام عليكم ${patient.fullName}،\n'
        'تجدون مرفقاً الوصفة الطبية من $doctorName.\n'
        'تاريخ الزيارة: ${_formatDate(DateTime.now())}';

    // نسخ مسار الملف للـ Clipboard تلقائياً
    await Clipboard.setData(ClipboardData(text: file.path));

    // فتح مجلد الملف في Explorer
    await _openFolder(file.path);

    // فتح واتساب ويب بعد ثانية (حتى يفتح المجلد أولاً)
    await Future.delayed(const Duration(milliseconds: 800));

    final whatsappUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(
      whatsappUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      return WhatsAppResult.failure('تعذر فتح واتساب.');
    }

    return WhatsAppResult.desktopSuccess(
      pdfPath: file.path,
      message:
          'تم نسخ مسار الوصفة تلقائياً\nافتح واتساب واضغط المرفق ثم الصق المسار',
    );
  }

  static Future<void> _openFolder(String filePath) async {
    final folder = p.dirname(filePath);
    try {
      // Windows Explorer يفتح المجلد ويحدد الملف
      await Process.run('explorer', ['/select,', filePath]);
    } catch (_) {
      try {
        final uri = Uri.parse('file:///$folder');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

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

  static Future<File> _saveTempPdf({
    required List<int> bytes,
    required String patientName,
    required DateTime visitDate,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = patientName.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_');
    final dateStr = '${visitDate.day}-${visitDate.month}-${visitDate.year}';
    final fileName = 'وصفة_${safeName}_$dateStr.pdf';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes);
    return file;
  }

  static String _cleanPhone(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+963${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+963$cleaned';
    }
    return cleaned;
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

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

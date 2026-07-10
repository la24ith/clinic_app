import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/database/database.dart';

class PrescriptionService {
  // طباعة وصفة مباشرة
  static Future<void> printPrescription({
    required Visit visit,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    final pdf = await _buildPdf(
      visit: visit,
      patient: patient,
      setting: setting,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name:
          'وصفة_${patient.fullName}_${visit.visitDate.day}'
          '-${visit.visitDate.month}-${visit.visitDate.year}',
    );
  }

  // معاينة الوصفة قبل الطباعة
  static Future<void> previewPrescription({
    required Visit visit,
    required Patient patient,
    required ClinicSetting setting,
    required dynamic context,
  }) async {
    final pdf = await _buildPdf(
      visit: visit,
      patient: patient,
      setting: setting,
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'وصفة_${patient.fullName}.pdf',
    );
  }

  static Future<pw.Document> _buildPdf({
    required Visit visit,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    // تحميل الصور إن وجدت
    pw.MemoryImage? logoImage;
    pw.MemoryImage? stampImage;
    pw.MemoryImage? signatureImage;

    if (setting.logoPath != null) {
      final f = File(setting.logoPath!);
      if (await f.exists()) {
        logoImage = pw.MemoryImage(await f.readAsBytes());
      }
    }
    if (setting.stampPath != null) {
      final f = File(setting.stampPath!);
      if (await f.exists()) {
        stampImage = pw.MemoryImage(await f.readAsBytes());
      }
    }
    if (setting.signaturePath != null) {
      final f = File(setting.signaturePath!);
      if (await f.exists()) {
        signatureImage = pw.MemoryImage(await f.readAsBytes());
      }
    }

    final baseTheme = pw.ThemeData.withFont(base: arabicFont, bold: arabicBold);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        theme: baseTheme,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── الرأس (Header) ──
              _buildHeader(
                setting: setting,
                logoImage: logoImage,
                boldFont: arabicBold,
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
              pw.SizedBox(height: 8),

              // ── بيانات المريض ──
              _buildPatientInfo(
                patient: patient,
                visit: visit,
                boldFont: arabicBold,
              ),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // ── الشكوى ──
              _buildSection(
                title: 'الشكوى:',
                content: visit.complaint,
                bold: arabicBold,
                base: arabicFont,
              ),
              pw.SizedBox(height: 8),

              // ── التشخيص ──
              _buildSection(
                title: 'التشخيص:',
                content: visit.diagnosis,
                bold: arabicBold,
                base: arabicFont,
              ),
              pw.SizedBox(height: 8),

              // ── العلاج / الوصفة ──
              _buildSection(
                title: 'العلاج / الوصفة:',
                content: visit.treatment,
                bold: arabicBold,
                base: arabicFont,
                highlight: true,
              ),

              // ── الملاحظات ──
              if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _buildSection(
                  title: 'ملاحظات:',
                  content: visit.notes!,
                  bold: arabicBold,
                  base: arabicFont,
                ),
              ],

              pw.Spacer(),

              // ── التذييل (ختم + توقيع) ──
              _buildFooter(
                setting: setting,
                stampImage: stampImage,
                signatureImage: signatureImage,
                boldFont: arabicBold,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static Future<pw.Document> buildPdfDocument({
    required Visit visit,
    required Patient patient,
    required ClinicSetting setting,
  }) async {
    return _buildPdf(visit: visit, patient: patient, setting: setting);
  }

  // ── الرأس ──
  static pw.Widget _buildHeader({
    required ClinicSetting setting,
    required pw.MemoryImage? logoImage,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // بيانات العيادة
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              setting.doctorName ?? 'اسم الطبيب',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                color: PdfColors.blueGrey900,
              ),
            ),
            if (setting.specialty != null)
              pw.Text(
                setting.specialty!,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: PdfColors.blueGrey600,
                ),
              ),
            if (setting.clinicPhone != null)
              pw.Text(
                '📞 ${setting.clinicPhone}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey500),
              ),
            if (setting.clinicAddress != null)
              pw.Text(
                setting.clinicAddress!,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey500),
              ),
          ],
        ),

        // الشعار
        if (logoImage != null)
          pw.Image(logoImage, width: 70, height: 70)
        else
          pw.Container(
            width: 70,
            height: 70,
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                'شعار',
                style: pw.TextStyle(
                  font: boldFont,
                  color: PdfColors.blueGrey400,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── بيانات المريض ──
  static pw.Widget _buildPatientInfo({
    required Patient patient,
    required Visit visit,
    required pw.Font boldFont,
  }) {
    final age = patient.birthDate != null
        ? '${DateTime.now().difference(patient.birthDate!).inDays ~/ 365} سنة'
        : patient.manualAge != null
        ? '${patient.manualAge} سنة'
        : '—';
    final gender = patient.gender.name == 'male' ? 'ذكر' : 'أنثى';
    final date = visit.visitDate;
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _infoItem('المريض', patient.fullName, boldFont),
          _infoItem('الجنس', gender, boldFont),
          _infoItem('العمر', age, boldFont),
          _infoItem('التاريخ', dateStr, boldFont),
        ],
      ),
    );
  }

  static pw.Widget _infoItem(String label, String value, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey500),
        ),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 11)),
      ],
    );
  }

  // ── قسم نصي (شكوى / تشخيص / علاج) ──
  static pw.Widget _buildSection({
    required String title,
    required String content,
    required pw.Font bold,
    required pw.Font base,
    bool highlight = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: highlight ? PdfColors.blue50 : PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: highlight
            ? pw.Border.all(color: PdfColors.blue200, width: 0.5)
            : null,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: bold,
              fontSize: 11,
              color: highlight ? PdfColors.blue900 : PdfColors.blueGrey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            content,
            style: pw.TextStyle(
              font: base,
              fontSize: highlight ? 12 : 11,
              lineSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── التذييل ──
  static pw.Widget _buildFooter({
    required ClinicSetting setting,
    required pw.MemoryImage? stampImage,
    required pw.MemoryImage? signatureImage,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // التوقيع
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (signatureImage != null)
                  pw.Image(signatureImage, width: 80, height: 40)
                else
                  pw.SizedBox(height: 40),
                pw.Text(
                  'التوقيع',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 9,
                    color: PdfColors.blueGrey400,
                  ),
                ),
              ],
            ),

            // العنوان
            if (setting.clinicAddress != null)
              pw.Text(
                setting.clinicAddress!,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400),
              ),

            // الختم
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (stampImage != null)
                  pw.Image(stampImage, width: 60, height: 60)
                else
                  pw.SizedBox(height: 60),
                pw.Text(
                  'الختم',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 9,
                    color: PdfColors.blueGrey400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

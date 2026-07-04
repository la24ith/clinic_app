import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database.dart';

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  Stream<ClinicSetting?> watchSettings() => db.watchClinicSettings();

  Future<String?> updateSettings(ClinicSettingsCompanion settings) async {
    try {
      await db.updateSettings(settings);
      return null;
    } catch (e) {
      return 'فشل الحفظ: $e';
    }
  }

  // نسخ الصورة لمجلد دائم داخل بيانات التطبيق وإرجاع المسار الجديد
  Future<String?> saveImage(String sourcePath, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'clinic_images'));
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
      final dest = File(p.join(imagesDir.path, fileName));
      await File(sourcePath).copy(dest.path);
      return dest.path;
    } catch (e) {
      return null;
    }
  }

  // نسخ احتياطي يدوي
  Future<String?> backupNow(String destinationFolder) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(appDir.path, 'clinic.sqlite'));
      if (!await dbFile.exists()) return 'ملف قاعدة البيانات غير موجود';

      final now = DateTime.now();
      final name =
          'clinic_backup_${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}.sqlite';

      final dest = File(p.join(destinationFolder, name));
      await dbFile.copy(dest.path);

      // تحديث وقت آخر نسخة احتياطية
      await db.updateSettings(
        ClinicSettingsCompanion(lastBackupAt: Value(DateTime.now())),
      );
      return null;
    } catch (e) {
      return 'فشل النسخ الاحتياطي: $e';
    }
  }
}

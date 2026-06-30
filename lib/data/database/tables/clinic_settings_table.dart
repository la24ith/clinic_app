import 'package:drift/drift.dart';

@DataClassName('ClinicSetting')
class ClinicSettings extends Table {
  // هذا الجدول سيحتوي دائماً على صف واحد فقط (Singleton Row)
  IntColumn get id => integer().autoIncrement()();

  TextColumn get doctorName => text().nullable()();
  TextColumn get specialty => text().nullable()();
  TextColumn get clinicPhone => text().nullable()();
  TextColumn get clinicAddress => text().nullable()();

  // مسارات الصور المحلية (وليس الصور نفسها) - نخزن فقط مكان الملف
  TextColumn get logoPath => text().nullable()();
  TextColumn get stampPath => text().nullable()();
  TextColumn get signaturePath => text().nullable()();

  // إعدادات النسخ الاحتياطي
  BoolColumn get autoBackupEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get backupFolderPath => text().nullable()();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();
}

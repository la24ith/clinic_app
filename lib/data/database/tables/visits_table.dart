import 'package:drift/drift.dart';
import 'patients_table.dart';
import 'users_table.dart';

@DataClassName('Visit')
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();

  // الربط بجدول المرضى (Foreign Key)
  // onDelete: restrict يعني: لا يمكن حذف مريض إذا كان له زيارات مرتبطة
  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.restrict)();

  // أي مستخدم (طبيب) قام بتسجيل هذه الزيارة
  IntColumn get doctorId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();

  DateTimeColumn get visitDate => dateTime().withDefault(currentDateAndTime)();

  // سبب الزيارة - "يشكو من..."
  TextColumn get complaint => text()();

  // التشخيص
  TextColumn get diagnosis => text()();

  // العلاج / الوصفة الطبية
  TextColumn get treatment => text()();

  // ملاحظات إضافية
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

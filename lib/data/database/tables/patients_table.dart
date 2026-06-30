import 'package:drift/drift.dart';

enum Gender { male, female }

@DataClassName('Patient')
class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get fullName => text().withLength(min: 2, max: 100)();

  TextColumn get gender => textEnum<Gender>()();

  // تاريخ الميلاد اختياري - لأنه كثير مرضى (خصوصاً كبار السن)
  // ما عندهم أوراق ثبوتية دقيقة، فبيدخل الطبيب العمر يدوياً بدل هيك
  DateTimeColumn get birthDate => dateTime().nullable()();

  // العمر اليدوي - يُستخدم فقط إذا كان birthDate فارغاً
  IntColumn get manualAge => integer().nullable()();

  // الهاتف إلزامي - نستخدمه كمعرّف ثانوي للبحث السريع
  TextColumn get phone => text().withLength(min: 7, max: 20)();

  TextColumn get address => text().nullable()();

  TextColumn get notes => text().nullable()();

  // الأرشفة بدل الحذف الفعلي (كما اتفقنا في المواصفات)
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

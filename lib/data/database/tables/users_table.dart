import 'package:drift/drift.dart';

// تعريف الأدوار كقيم ثابتة (Enum) بدل نص حر
// هيك نضمن إنه ما حدا يكتب "دكتور" غلط بدل "doctor"
enum UserRole { doctor, assistant }

@DataClassName('User')
class Users extends Table {
  // المعرف الأساسي - تلقائي التزايد
  IntColumn get id => integer().autoIncrement()();

  // اسم المستخدم لتسجيل الدخول - يجب أن يكون فريداً (unique)
  TextColumn get username => text().withLength(min: 3, max: 50)();

  // كلمة المرور - سنخزن الـ Hash وليس النص الصريح أبداً
  TextColumn get passwordHash => text()();

  // الاسم الكامل المعروض بالواجهة (مثال: "د. أحمد الشامي")
  TextColumn get fullName => text()();

  // الدور: نخزنه كنص لكن نقيّده بقيم محددة عبر Enum بمستوى التطبيق
  TextColumn get role => textEnum<UserRole>()();

  // الاختصاص الطبي - يظهر فقط لو كان role = doctor
  TextColumn get specialty => text().nullable()();

  // رقم الهاتف
  TextColumn get phone => text().nullable()();

  // هل الحساب مفعّل أو معطّل (بدل حذف المستخدم نهائياً)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // فرض التفرد (Uniqueness) على اسم المستخدم
  @override
  List<Set<Column>> get uniqueKeys => [
    {username},
  ];
}

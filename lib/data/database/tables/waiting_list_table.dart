import 'package:drift/drift.dart';
import 'patients_table.dart';
import 'appointments_table.dart';

enum WaitingStatus { waiting, withDoctor, done }

@DataClassName('WaitingListEntry')
class WaitingListEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.restrict)();

  // ربط اختياري بموعد مسبق (لو المريض جاء بموعد محجوز مسبقاً)
  // nullable لأن أغلب الحالات: المريض يأتي مباشرة بدون حجز مسبق
  IntColumn get appointmentId =>
      integer().nullable().references(Appointments, #id)();

  // الدور اليومي - رقم تسلسلي يُعاد ترقيمه كل يوم من 1
  IntColumn get dailyOrder => integer()();

  DateTimeColumn get arrivalTime =>
      dateTime().withDefault(currentDateAndTime)();

  // وقت دخول المريض فعلياً عند الطبيب - يُسجَّل تلقائياً عند تغيير الحالة
  DateTimeColumn get enteredDoctorAt => dateTime().nullable()();

  // وقت انتهاء الكشف
  DateTimeColumn get finishedAt => dateTime().nullable()();

  TextColumn get status => textEnum<WaitingStatus>().withDefault(
    Constant(WaitingStatus.waiting.name),
  )();

  // تاريخ اليوم (بدون وقت) - لتسهيل استعلام "قائمة انتظار اليوم"
  DateTimeColumn get listDate => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

import 'package:drift/drift.dart';
import 'patients_table.dart';

enum AppointmentStatus { scheduled, arrived, noShow, cancelled }

@DataClassName('Appointment')
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get patientId =>
      integer().references(Patients, #id, onDelete: KeyAction.restrict)();

  // تاريخ ووقت الموعد مدمجان بحقل واحد (DateTime يحتوي الاثنين)
  DateTimeColumn get appointmentDateTime => dateTime()();

  TextColumn get reason => text().nullable()(); // سبب الزيارة المتوقع

  TextColumn get note => text().nullable()();

  TextColumn get status => textEnum<AppointmentStatus>().withDefault(
    Constant(AppointmentStatus.scheduled.name),
  )();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

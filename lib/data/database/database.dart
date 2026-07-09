import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/users_table.dart';
import 'tables/patients_table.dart';
import 'tables/visits_table.dart';
import 'tables/appointments_table.dart';
import 'tables/waiting_list_table.dart';
import 'tables/clinic_settings_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Patients,
    Visits,
    Appointments,
    WaitingListEntries,
    ClinicSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // مُنشئ بديل خاص بالاختبارات (Unit Tests)
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  // ----------------------------------------------------------------
  // استعلامات المرضى (Patients)
  // ----------------------------------------------------------------

  Stream<List<Patient>> watchAllPatients() {
    final query = select(patients)
      ..where((p) => p.isArchived.equals(false))
      ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]);
    return query.watch();
  }

  Stream<List<Patient>> watchSearchPatients(String keyword) {
    final pattern = '%$keyword%';
    final query = select(patients)
      ..where(
        (p) =>
            p.isArchived.equals(false) &
            (p.fullName.like(pattern) | p.phone.like(pattern)),
      );
    return query.watch();
  }

  Future<Patient> getPatientById(int id) {
    return (select(patients)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<int> addPatient(PatientsCompanion patient) {
    return into(patients).insert(patient);
  }

  Future<bool> updatePatient(Patient patient) {
    return update(patients).replace(patient);
  }

  // أرشفة (وليس حذف فعلي) - تطبيقاً لسياسة الأرشفة المتفق عليها
  Future<int> archivePatient(int id) {
    return (update(patients)..where((p) => p.id.equals(id))).write(
      const PatientsCompanion(isArchived: Value(true)),
    );
  }

  Future<int> restorePatient(int id) {
    return (update(patients)..where((p) => p.id.equals(id))).write(
      const PatientsCompanion(isArchived: Value(false)),
    );
  }

  // ----------------------------------------------------------------
  // استعلامات الزيارات (Visits)
  // ----------------------------------------------------------------

  Stream<List<Visit>> watchVisitsForPatient(int patientId) {
    final query = select(visits)
      ..where((v) => v.patientId.equals(patientId))
      ..orderBy([(v) => OrderingTerm.desc(v.visitDate)]);
    return query.watch();
  }

  Future<int> addVisit(VisitsCompanion visit) {
    return into(visits).insert(visit);
  }

  // ----------------------------------------------------------------
  // استعلامات المواعيد (Appointments)
  // ----------------------------------------------------------------

  Stream<List<Appointment>> watchAppointmentsForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = select(appointments)
      ..where(
        (a) =>
            a.appointmentDateTime.isBiggerOrEqualValue(startOfDay) &
            a.appointmentDateTime.isSmallerThanValue(endOfDay),
      )
      ..orderBy([(a) => OrderingTerm.asc(a.appointmentDateTime)]);
    return query.watch();
  }

  Future<int> addAppointment(AppointmentsCompanion appointment) {
    return into(appointments).insert(appointment);
  }

  Future<int> updateAppointmentStatus(int id, AppointmentStatus status) {
    return (update(appointments)..where((a) => a.id.equals(id))).write(
      AppointmentsCompanion(status: Value(status..name)),
    );
  }

  // ----------------------------------------------------------------
  // استعلامات قائمة الانتظار (WaitingListEntries)
  // ----------------------------------------------------------------

  // أهم استعلام بالنظام بالكامل: قائمة انتظار اليوم الحالي، Real-time
  Stream<List<WaitingListEntry>> watchTodayWaitingList() {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final query = select(waitingListEntries)
      ..where((w) => w.listDate.equals(dateOnly))
      ..orderBy([(w) => OrderingTerm.asc(w.dailyOrder)]);
    return query.watch();
  }

  //للارشييييف
  Stream<List<Patient>> watchArchivedPatients() {
    final query = select(patients)
      ..where((p) => p.isArchived.equals(true))
      ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]);
    return query.watch();
  }

  // حساب الدور التالي لليوم الحالي
  Future<int> getNextDailyOrder() async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final query = select(waitingListEntries)
      ..where((w) => w.listDate.equals(dateOnly))
      ..orderBy([(w) => OrderingTerm.desc(w.dailyOrder)])
      ..limit(1);
    final last = await query.getSingleOrNull();
    return (last?.dailyOrder ?? 0) + 1;
  }

  Future<int> addToWaitingList(WaitingListEntriesCompanion entry) {
    return into(waitingListEntries).insert(entry);
  }

  // تغيير الحالة (بانتظار / داخل الطبيب / انتهى) - بضغطة واحدة من الواجهة
  Future<int> updateWaitingStatus(int id, WaitingStatus status) {
    final companion = WaitingListEntriesCompanion(
      status: Value(status..name),
      enteredDoctorAt: status == WaitingStatus.withDoctor
          ? Value(DateTime.now())
          : const Value.absent(),
      finishedAt: status == WaitingStatus.done
          ? Value(DateTime.now())
          : const Value.absent(),
    );
    return (update(
      waitingListEntries,
    )..where((w) => w.id.equals(id))).write(companion);
  }

  // ----------------------------------------------------------------
  // استعلامات إعدادات العيادة (Singleton Row)
  // ----------------------------------------------------------------

  Stream<ClinicSetting?> watchClinicSettings() {
    return select(clinicSettings).watchSingleOrNull();
  }

  // عند أول تشغيل، ننشئ صف الإعدادات الافتراضي إن لم يكن موجوداً
  Future<void> ensureSettingsRowExists() async {
    final existing = await select(clinicSettings).getSingleOrNull();
    if (existing == null) {
      await into(clinicSettings).insert(const ClinicSettingsCompanion());
    }
  }

  Future<void> updateSettings(ClinicSettingsCompanion settings) async {
    final existing = await select(clinicSettings).getSingleOrNull();
    if (existing != null) {
      await (update(
        clinicSettings,
      )..where((s) => s.id.equals(existing.id))).write(settings);
    } else {
      await into(clinicSettings).insert(settings);
    }
  }
}

// ----------------------------------------------------------------
// فتح الاتصال بقاعدة البيانات الفعلية على القرص
// ----------------------------------------------------------------
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'clinic.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

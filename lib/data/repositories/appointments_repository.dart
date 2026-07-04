import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/tables/appointments_table.dart';
import '../database/tables/patients_table.dart';

class AppointmentWithPatient {
  final Appointment appointment;
  final Patient patient;
  AppointmentWithPatient({required this.appointment, required this.patient});
}

class AppointmentsRepository {
  final AppDatabase db;
  AppointmentsRepository(this.db);

  Stream<List<AppointmentWithPatient>> watchDayWithPatients(DateTime day) {
    return db.watchAppointmentsForDay(day).asyncMap((appointments) async {
      final result = <AppointmentWithPatient>[];
      for (final a in appointments) {
        try {
          final patient = await db.getPatientById(a.patientId);
          result.add(AppointmentWithPatient(appointment: a, patient: patient));
        } catch (_) {}
      }
      return result;
    });
  }

  Future<String?> addAppointment({
    required int patientId,
    required DateTime dateTime,
    String? reason,
    String? note,
  }) async {
    try {
      await db.addAppointment(
        AppointmentsCompanion.insert(
          patientId: patientId,
          appointmentDateTime: dateTime,
          reason: Value(reason),
          note: Value(note),
        ),
      );
      return null;
    } catch (e) {
      return 'فشل حفظ الموعد: $e';
    }
  }

  Future<String?> updateStatus(int id, AppointmentStatus status) async {
    try {
      await db.updateAppointmentStatus(id, status);
      return null;
    } catch (e) {
      return 'فشل تحديث الحالة: $e';
    }
  }

  Future<List<Patient>> searchPatients(String keyword) {
    return db.watchSearchPatients(keyword).first;
  }
}

import 'package:clinic_app/data/database/tables/patients_table.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';

class PatientsRepository {
  final AppDatabase db;

  PatientsRepository(this.db);

  Stream<List<Patient>> watchAllPatients() {
    return db.watchAllPatients();
  }

  Stream<List<Patient>> searchPatients(String keyword) {
    if (keyword.trim().isEmpty) {
      return db.watchAllPatients();
    }
    return db.watchSearchPatients(keyword.trim());
  }

  Future<Patient> getPatientById(int id) {
    return db.getPatientById(id);
  }

  Future<int> addPatient({
    required String fullName,
    required Gender gender,
    DateTime? birthDate,
    int? manualAge,
    required String phone,
    String? address,
    String? notes,
  }) {
    return db.addPatient(
      PatientsCompanion.insert(
        fullName: fullName,
        gender: gender,
        phone: phone,
        birthDate: Value(birthDate),
        manualAge: Value(manualAge),
        address: Value(address),
        notes: Value(notes),
      ),
    );
  }

  Future<bool> updatePatient(Patient patient) {
    return db.updatePatient(patient.copyWith(updatedAt: DateTime.now()));
  }

  Future<int> archivePatient(int id) {
    return db.archivePatient(id);
  }
}

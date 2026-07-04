import 'package:clinic_app/data/database/database.dart';
import 'package:drift/drift.dart';

class VisitsRepository {
  final AppDatabase db;
  VisitsRepository(this.db);

  Stream<List<Visit>> watchVisitsForPatient(int patientId) {
    return db.watchVisitsForPatient(patientId);
  }

  Future<String?> addVisit({
    required int patientId,
    required int doctorId,
    required String complaint,
    required String diagnosis,
    required String treatment,
    String? notes,
  }) async {
    try {
      await db.addVisit(
        VisitsCompanion.insert(
          patientId: patientId,
          doctorId: doctorId,
          complaint: complaint,
          diagnosis: diagnosis,
          treatment: treatment,
          notes: Value(notes),
        ),
      );
      return null;
    } catch (e) {
      return 'فشل حفظ الزيارة: $e';
    }
  }
}

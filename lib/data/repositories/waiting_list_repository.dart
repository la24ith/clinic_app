import '../database/database.dart';
import '../database/tables/waiting_list_table.dart';
import '../database/tables/patients_table.dart';

// موديل مدمج: بيانات قائمة الانتظار + بيانات المريض معاً
class WaitingEntry {
  final WaitingListEntry entry;
  final Patient patient;
  WaitingEntry({required this.entry, required this.patient});
}

class WaitingListRepository {
  final AppDatabase db;
  WaitingListRepository(this.db);

  // Stream يجمع بيانات الانتظار مع بيانات المريض لكل صف
  Stream<List<WaitingEntry>> watchTodayWithPatients() {
    return db.watchTodayWaitingList().asyncMap((entries) async {
      final result = <WaitingEntry>[];
      for (final entry in entries) {
        try {
          final patient = await db.getPatientById(entry.patientId);
          result.add(WaitingEntry(entry: entry, patient: patient));
        } catch (_) {
          // المريض غير موجود - نتجاهل
        }
      }
      return result;
    });
  }

  Future<String?> addToWaiting(int patientId) async {
    try {
      final order = await db.getNextDailyOrder();
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);

      await db.addToWaitingList(
        WaitingListEntriesCompanion.insert(
          patientId: patientId,
          dailyOrder: order,
          listDate: dateOnly,
        ),
      );
      return null;
    } catch (e) {
      return 'فشل الإضافة: $e';
    }
  }

  Future<String?> updateStatus(int id, WaitingStatus status) async {
    try {
      await db.updateWaitingStatus(id, status);
      return null;
    } catch (e) {
      return 'فشل تحديث الحالة: $e';
    }
  }

  // بحث سريع عن مريض لإضافته للقائمة
  Future<List<Patient>> searchPatients(String keyword) {
    return db.watchSearchPatients(keyword).first;
  }
}

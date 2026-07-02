import 'package:clinic_app/data/database/database.dart';
import 'package:clinic_app/data/database/tables/waiting_list_table.dart';
import 'package:drift/drift.dart';

class DashboardStats {
  final int todayPatients;
  final int waiting;
  final int done;
  final int upcomingAppointments;

  const DashboardStats({
    required this.todayPatients,
    required this.waiting,
    required this.done,
    required this.upcomingAppointments,
  });
}

class DashboardRepository {
  final AppDatabase db;
  DashboardRepository(this.db);

  Stream<DashboardStats> watchTodayStats() {
    return db.watchTodayWaitingList().asyncMap((entries) async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final waiting = entries
          .where((e) => e.status == WaitingStatus.waiting)
          .length;
      final done = entries.where((e) => e.status == WaitingStatus.done).length;

      // المواعيد القادمة من الآن لنهاية اليوم
      final upcoming =
          await (db.select(db.appointments)..where(
                (a) =>
                    a.appointmentDateTime.isBiggerOrEqualValue(now) &
                    a.appointmentDateTime.isSmallerThanValue(endOfDay),
              ))
              .get();

      return DashboardStats(
        todayPatients: entries.length,
        waiting: waiting,
        done: done,
        upcomingAppointments: upcoming.length,
      );
    });
  }

  // آخر 5 مرضى بقائمة الانتظار اليوم (للـ Widget المصغّر)
  Stream<List<WaitingListEntry>> watchRecentWaiting() {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final query = db.select(db.waitingListEntries)
      ..where(
        (w) =>
            w.listDate.equals(dateOnly) &
            w.status.equals(WaitingStatus.waiting.name),
      )
      ..orderBy([(w) => OrderingTerm.asc(w.dailyOrder)])
      ..limit(5);
    return query.watch();
  }
}

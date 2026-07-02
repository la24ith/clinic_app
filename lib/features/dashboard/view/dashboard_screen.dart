import 'package:clinic_app/data/database/database.dart';
import 'package:clinic_app/features/dashboard/repositories/dashboard_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injector.dart';
import '../../../core/router/app_router.dart';
import '../../../data/database/tables/waiting_list_table.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(getIt<DashboardRepository>()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الترويسة العلوية
                _buildHeader(context),
                const SizedBox(height: 28),

                // البطاقات الإحصائية
                _buildStatCards(context, state),
                const SizedBox(height: 28),

                // الصف السفلي: قائمة الانتظار + الأزرار السريعة
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // قائمة الانتظار المصغّرة
                    Expanded(
                      flex: 3,
                      child: _buildWaitingWidget(context, state),
                    ),
                    const SizedBox(width: 20),
                    // الأزرار السريعة
                    Expanded(flex: 2, child: _buildQuickActions(context)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final dateStr =
        '${days[now.weekday - 1]}، ${now.day} ${months[now.month - 1]} ${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لوحة التحكم',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F3864),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        // الوقت الحالي
        _LiveClock(),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, DashboardState state) {
    final stats = state.stats;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'مرضى اليوم',
            value: stats?.todayPatients ?? 0,
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF1F3864),
            onTap: () => context.go(AppRoutes.waitingList),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'بانتظار',
            value: stats?.waiting ?? 0,
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => context.go(AppRoutes.waitingList),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'تمت المعاينة',
            value: stats?.done ?? 0,
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            onTap: () => context.go(AppRoutes.waitingList),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'مواعيد قادمة',
            value: stats?.upcomingAppointments ?? 0,
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => context.go(AppRoutes.appointments),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingWidget(BuildContext context, DashboardState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قائمة الانتظار',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3864),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.waitingList),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          state.recentWaiting.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'لا يوجد مرضى بانتظار حالياً',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.recentWaiting.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (context, index) {
                    final entry = state.recentWaiting[index];
                    return _WaitingTile(entry: entry);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F3864),
            ),
          ),
          const SizedBox(height: 16),
          _QuickActionButton(
            icon: Icons.person_add_rounded,
            label: 'إضافة مريض',
            color: const Color(0xFF1F3864),
            onTap: () => context.go(AppRoutes.patients),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.hourglass_top_rounded,
            label: 'قائمة الانتظار',
            color: const Color(0xFFF59E0B),
            onTap: () => context.go(AppRoutes.waitingList),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.calendar_month_rounded,
            label: 'موعد جديد',
            color: const Color(0xFF6366F1),
            onTap: () => context.go(AppRoutes.appointments),
          ),
          const SizedBox(height: 10),
          _QuickActionButton(
            icon: Icons.people_rounded,
            label: 'البحث عن مريض',
            color: const Color(0xFF10B981),
            onTap: () => context.go(AppRoutes.patients),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Widgets مساعدة
// ─────────────────────────────────────────

class _LiveClock extends StatefulWidget {
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;
  late final Stream<DateTime> _stream;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _stream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _stream,
      initialData: _now,
      builder: (context, snapshot) {
        final t = snapshot.data!;
        final h = t.hour.toString().padLeft(2, '0');
        final m = t.minute.toString().padLeft(2, '0');
        final s = t.second.toString().padLeft(2, '0');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1F3864),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$h:$m:$s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingTile extends StatelessWidget {
  final WaitingListEntry entry;
  const _WaitingTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final arrival = entry.arrivalTime;
    final h = arrival.hour.toString().padLeft(2, '0');
    final m = arrival.minute.toString().padLeft(2, '0');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1F3864).withOpacity(0.1),
        child: Text(
          '#${entry.dailyOrder}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F3864),
          ),
        ),
      ),
      title: Text(
        'مريض #${entry.patientId}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('وصل الساعة $h:$m'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'بانتظار',
          style: TextStyle(
            color: Color(0xFFD97706),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 18),
        label: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

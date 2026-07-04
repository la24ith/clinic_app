import 'package:clinic_app/features/appointments/widgets/add_appointment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../data/database/tables/appointments_table.dart';
import '../../../data/repositories/appointments_repository.dart';
import '../../../data/repositories/waiting_list_repository.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/appointments_state.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppointmentsCubit(
        repository: getIt<AppointmentsRepository>(),
        waitingRepo: getIt<WaitingListRepository>(),
      ),
      child: const _AppointmentsView(),
    );
  }
}

class _AppointmentsView extends StatefulWidget {
  const _AppointmentsView();

  @override
  State<_AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<_AppointmentsView> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── الترويسة ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المواعيد',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3864),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('موعد جديد'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3864),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── منتقي اليوم ──
            _DayPicker(
              selectedDay: _selectedDay,
              onDaySelected: (day) {
                setState(() => _selectedDay = day);
                context.read<AppointmentsCubit>().selectDay(day);
              },
            ),
            const SizedBox(height: 20),

            // ── قائمة المواعيد ──
            Expanded(
              child: BlocBuilder<AppointmentsCubit, AppointmentsState>(
                builder: (context, state) {
                  if (state is AppointmentsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AppointmentsError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is AppointmentsLoaded) {
                    if (state.appointments.isEmpty) {
                      return _buildEmpty();
                    }
                    return _buildList(context, state.appointments);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مواعيد لهذا اليوم',
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط "موعد جديد" لإضافة موعد',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AppointmentWithPatient> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس الجدول
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1F3864),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: _HeaderCell('الوقت')),
                Expanded(flex: 3, child: _HeaderCell('المريض')),
                Expanded(flex: 2, child: _HeaderCell('السبب')),
                Expanded(flex: 2, child: _HeaderCell('الحالة')),
                Expanded(flex: 2, child: _HeaderCell('إجراء')),
              ],
            ),
          ),
          // الصفوف
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) => _AppointmentRow(
                item: list[i],
                onArrived: () async {
                  final err = await context
                      .read<AppointmentsCubit>()
                      .markArrived(list[i].appointment.id, list[i].patient.id);
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(err)));
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تسجيل وصول ${list[i].patient.fullName} '
                          'وإضافته لقائمة الانتظار',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                onNoShow: () async {
                  final err = await context
                      .read<AppointmentsCubit>()
                      .markNoShow(list[i].appointment.id);
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<AppointmentsCubit>(),
        child: AddAppointmentDialog(
          initialDate: _selectedDay,
          repository: getIt<AppointmentsRepository>(),
        ),
      ),
    );
  }
}

// ── منتقي الأيام ──
class _DayPicker extends StatelessWidget {
  final DateTime selectedDay;
  final void Function(DateTime) onDaySelected;

  const _DayPicker({required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // السابق
          IconButton(
            onPressed: () =>
                onDaySelected(selectedDay.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right),
          ),

          // أيام الأسبوع
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final day = _startOfWeek(selectedDay).add(Duration(days: i));
                final isSelected = _isSameDay(day, selectedDay);
                final isToday = _isSameDay(day, DateTime.now());

                return GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1F3864)
                          : isToday
                          ? const Color(0xFF1F3864).withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _dayName(day.weekday),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                ? const Color(0xFF1F3864)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // التالي
          IconButton(
            onPressed: () =>
                onDaySelected(selectedDay.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
          ),

          // زر "اليوم"
          OutlinedButton(
            onPressed: () => onDaySelected(DateTime.now()),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1F3864)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'اليوم',
              style: TextStyle(color: Color(0xFF1F3864)),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _startOfWeek(DateTime day) {
    return day.subtract(Duration(days: day.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayName(int weekday) {
    const names = [
      '',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return names[weekday];
  }
}

// ── رأس الجدول ──
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}

// ── صف موعد ──
class _AppointmentRow extends StatelessWidget {
  final AppointmentWithPatient item;
  final VoidCallback onArrived;
  final VoidCallback onNoShow;

  const _AppointmentRow({
    required this.item,
    required this.onArrived,
    required this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final a = item.appointment;
    final p = item.patient;
    final h = a.appointmentDateTime.hour.toString().padLeft(2, '0');
    final m = a.appointmentDateTime.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // الوقت
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1F3864).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$h:$m',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F3864),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // المريض
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF1F3864).withOpacity(0.1),
                  child: Text(
                    p.fullName.isNotEmpty ? p.fullName[0] : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3864),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p.phone,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // السبب
          Expanded(
            flex: 2,
            child: Text(
              a.reason ?? '—',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // الحالة
          Expanded(flex: 2, child: _StatusBadge(status: a.status)),

          // الإجراء
          Expanded(flex: 2, child: _buildAction(a.status)),
        ],
      ),
    );
  }

  Widget _buildAction(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Row(
          children: [
            _ActionBtn(
              label: 'حضر',
              color: const Color(0xFF10B981),
              icon: Icons.check_circle_outline,
              onTap: onArrived,
            ),
            const SizedBox(width: 6),
            _ActionBtn(
              label: 'غائب',
              color: Colors.red,
              icon: Icons.cancel_outlined,
              onTap: onNoShow,
            ),
          ],
        );
      case AppointmentStatus.arrived:
        return const Text(
          'تم التسجيل ✓',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        );
      case AppointmentStatus.noShow:
        return Text(
          'لم يحضر',
          style: TextStyle(color: Colors.red[400], fontSize: 13),
        );
      case AppointmentStatus.cancelled:
        return Text(
          'ملغى',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cfg['label'] as String,
        style: TextStyle(
          color: cfg['color'] as Color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, dynamic> _config() {
    switch (status) {
      case AppointmentStatus.scheduled:
        return {'label': 'مجدول', 'color': const Color(0xFF6366F1)};
      case AppointmentStatus.arrived:
        return {'label': 'حضر', 'color': const Color(0xFF10B981)};
      case AppointmentStatus.noShow:
        return {'label': 'لم يحضر', 'color': Colors.red};
      case AppointmentStatus.cancelled:
        return {'label': 'ملغى', 'color': Colors.grey};
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

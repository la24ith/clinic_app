import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables/waiting_list_table.dart';
import '../../../data/repositories/waiting_list_repository.dart';
import '../cubit/waiting_list_cubit.dart';
import '../cubit/waiting_list_state.dart';
import '../widgets/add_to_waiting_dialog.dart';

class WaitingListScreen extends StatelessWidget {
  const WaitingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WaitingListCubit(getIt<WaitingListRepository>()),
      child: const _WaitingListView(),
    );
  }
}

class _WaitingListView extends StatelessWidget {
  const _WaitingListView();

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قائمة الانتظار',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3864),
                      ),
                    ),
                    Text(
                      _todayLabel(),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('إضافة للانتظار'),
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

            // ── ملخص الحالات ──
            BlocBuilder<WaitingListCubit, WaitingListState>(
              builder: (context, state) {
                if (state is! WaitingListLoaded) return const SizedBox();
                return _buildSummary(state.entries);
              },
            ),
            const SizedBox(height: 20),

            // ── الجدول ──
            Expanded(
              child: BlocBuilder<WaitingListCubit, WaitingListState>(
                builder: (context, state) {
                  if (state is WaitingListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is WaitingListError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is WaitingListLoaded) {
                    if (state.entries.isEmpty) return _buildEmpty();
                    return _buildTable(context, state.entries);
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

  String _todayLabel() {
    final now = DateTime.now();
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
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _buildSummary(List<WaitingEntry> entries) {
    final waiting = entries
        .where((e) => e.entry.status == WaitingStatus.waiting)
        .length;
    final withDoc = entries
        .where((e) => e.entry.status == WaitingStatus.withDoctor)
        .length;
    final done = entries
        .where((e) => e.entry.status == WaitingStatus.done)
        .length;

    return Row(
      children: [
        _SummaryChip(
          label: 'بانتظار',
          count: waiting,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 12),
        _SummaryChip(
          label: 'داخل الطبيب',
          count: withDoc,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 12),
        _SummaryChip(
          label: 'انتهى',
          count: done,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 12),
        _SummaryChip(
          label: 'الإجمالي',
          count: entries.length,
          color: const Color(0xFF1F3864),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'قائمة الانتظار فارغة',
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط "إضافة للانتظار" لتسجيل أول مريض اليوم',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<WaitingEntry> entries) {
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
                SizedBox(width: 48),
                Expanded(flex: 1, child: _HeaderCell('الدور')),
                Expanded(flex: 3, child: _HeaderCell('اسم المريض')),
                Expanded(flex: 2, child: _HeaderCell('وقت الوصول')),
                Expanded(flex: 2, child: _HeaderCell('وقت الدخول')),
                Expanded(flex: 2, child: _HeaderCell('الحالة')),
                Expanded(flex: 2, child: _HeaderCell('تغيير الحالة')),
              ],
            ),
          ),
          // الصفوف
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) => _WaitingRow(
                entry: entries[i],
                onStatus: (status) async {
                  final error = await context
                      .read<WaitingListCubit>()
                      .updateStatus(entries[i].entry.id, status);
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                  // لو انتهى → اقترح تسجيل زيارة
                  if (status == WaitingStatus.done && context.mounted) {
                    _suggestVisit(context, entries[i].patient);
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
        value: context.read<WaitingListCubit>(),
        child: AddToWaitingDialog(repository: getIt<WaitingListRepository>()),
      ),
    );
  }

  // الاقتراح المنبثق عند انتهاء المريض (من المواصفات)
  void _suggestVisit(BuildContext context, Patient patient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('هل تريد تسجيل زيارة لـ ${patient.fullName}؟'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'تسجيل زيارة',
          onPressed: () {
            // سيُكمل لاحقاً عند بناء شاشة الزيارات
          },
        ),
      ),
    );
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

// ── ملخص الحالات ──
class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── صف مريض بالانتظار ──
class _WaitingRow extends StatelessWidget {
  final WaitingEntry entry;
  final Future<void> Function(WaitingStatus) onStatus;

  const _WaitingRow({required this.entry, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    final e = entry.entry;
    final patient = entry.patient;
    final status = e.status;

    return Container(
      color: _rowColor(status),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // مؤشر الحالة
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // الدور
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1F3864).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${e.dailyOrder}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F3864),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // اسم المريض
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  patient.phone,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // وقت الوصول
          Expanded(
            flex: 2,
            child: Text(
              _formatTime(e.arrivalTime),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // وقت الدخول للطبيب
          Expanded(
            flex: 2,
            child: Text(
              e.enteredDoctorAt != null ? _formatTime(e.enteredDoctorAt!) : '—',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),

          // بادج الحالة
          Expanded(flex: 2, child: _StatusBadge(status: status)),

          // أزرار تغيير الحالة
          Expanded(
            flex: 2,
            child: _StatusActions(status: status, onStatus: onStatus),
          ),
        ],
      ),
    );
  }

  Color _rowColor(WaitingStatus status) {
    switch (status) {
      case WaitingStatus.withDoctor:
        return const Color(0xFFEFF6FF);
      case WaitingStatus.done:
        return const Color(0xFFF0FDF4);
      default:
        return Colors.white;
    }
  }

  Color _statusColor(WaitingStatus status) {
    switch (status) {
      case WaitingStatus.waiting:
        return const Color(0xFFF59E0B);
      case WaitingStatus.withDoctor:
        return const Color(0xFF3B82F6);
      case WaitingStatus.done:
        return const Color(0xFF10B981);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── بادج الحالة ──
class _StatusBadge extends StatelessWidget {
  final WaitingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          color: config['color'] as Color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, dynamic> _config() {
    switch (status) {
      case WaitingStatus.waiting:
        return {
          'label': 'بانتظار',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
        };
      case WaitingStatus.withDoctor:
        return {
          'label': 'داخل الطبيب',
          'color': const Color(0xFF1D4ED8),
          'bg': const Color(0xFFDBEAFE),
        };
      case WaitingStatus.done:
        return {
          'label': 'انتهى',
          'color': const Color(0xFF065F46),
          'bg': const Color(0xFFD1FAE5),
        };
    }
  }
}

// ── أزرار تغيير الحالة ──
class _StatusActions extends StatelessWidget {
  final WaitingStatus status;
  final Future<void> Function(WaitingStatus) onStatus;

  const _StatusActions({required this.status, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case WaitingStatus.waiting:
        return _btn(
          label: 'إدخال',
          icon: Icons.login_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => onStatus(WaitingStatus.withDoctor),
        );
      case WaitingStatus.withDoctor:
        return _btn(
          label: 'إنهاء',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF10B981),
          onTap: () => onStatus(WaitingStatus.done),
        );
      case WaitingStatus.done:
        return Text(
          'اكتمل',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        );
    }
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

import 'package:clinic_app/data/repositories/visits_repository.dart';
import 'package:clinic_app/features/visits/widgets/add_visit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables/patients_table.dart';
import '../../../data/repositories/patients_repository.dart';
import '../../visits/cubit/visits_cubit.dart';
import '../../visits/cubit/visits_state.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

class MedicalFileScreen extends StatefulWidget {
  final int patientId;
  const MedicalFileScreen({super.key, required this.patientId});

  @override
  State<MedicalFileScreen> createState() => _MedicalFileScreenState();
}

class _MedicalFileScreenState extends State<MedicalFileScreen> {
  Patient? _patient;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final p = await getIt<PatientsRepository>().getPatientById(
        widget.patientId,
      );
      if (mounted)
        setState(() {
          _patient = p;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_patient == null) {
      return const Scaffold(body: Center(child: Text('المريض غير موجود')));
    }

    return BlocProvider(
      create: (_) => VisitsCubit(getIt<VisitsRepository>(), widget.patientId),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(child: _buildVisitsList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final p = _patient!;
    final age = p.birthDate != null
        ? '${DateTime.now().difference(p.birthDate!).inDays ~/ 365} سنة'
        : p.manualAge != null
        ? '${p.manualAge} سنة'
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF1F3864).withOpacity(0.1),
            child: Text(
              p.fullName.isNotEmpty ? p.fullName[0] : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F3864),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3864),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip(
                      icon: p.gender == Gender.male ? Icons.male : Icons.female,
                      label: p.gender == Gender.male ? 'ذكر' : 'أنثى',
                      color: p.gender == Gender.male
                          ? Colors.blue
                          : Colors.pink,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.cake_outlined,
                      label: age,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.phone_outlined,
                      label: p.phone,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _showAddVisit(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة زيارة'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F3864),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList(BuildContext context) {
    return BlocBuilder<VisitsCubit, VisitsState>(
      builder: (context, state) {
        if (state is VisitsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is VisitsError) {
          return Center(child: Text(state.message));
        }
        if (state is VisitsLoaded) {
          if (state.visits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد زيارات سابقة',
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط "إضافة زيارة" لتسجيل أول زيارة',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: state.visits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _VisitCard(visit: state.visits[i]),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showAddVisit(BuildContext context) {
    final authState = getIt<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<VisitsCubit>(),
        child: AddVisitDialog(
          doctorId: authState.user.id,
          patientName: _patient!.fullName,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;
  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F3864).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Color(0xFF1F3864),
              size: 20,
            ),
          ),
          title: Text(
            visit.diagnosis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(visit.visitDate),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _Section(
              title: 'الشكوى',
              content: visit.complaint,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'التشخيص',
              content: visit.diagnosis,
              color: const Color(0xFF1F3864),
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'العلاج / الوصفة',
              content: visit.treatment,
              color: const Color(0xFF10B981),
            ),
            if (visit.notes != null && visit.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Section(
                title: 'ملاحظات',
                content: visit.notes!,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final Color color;

  const _Section({
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
}

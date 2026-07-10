import 'package:clinic_app/core/services/prescription_service.dart';
import 'package:clinic_app/core/services/whatsapp_service.dart';
import 'package:clinic_app/data/repositories/settings_repository.dart';
import 'package:clinic_app/features/patients/widgets/medical_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/injector.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables/patients_table.dart';
import '../../../data/repositories/patients_repository.dart';
import '../../../data/repositories/visits_repository.dart';
import '../../visits/cubit/visits_cubit.dart';
import '../../visits/cubit/visits_state.dart';
import '../../visits/widgets/add_visit_dialog.dart';
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
  ClinicSetting? _setting; // ← أضف هاد
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final p = await getIt<PatientsRepository>().getPatientById(
        widget.patientId,
      );
      // جلب الإعدادات أيضاً
      final s = await getIt<SettingsRepository>().watchSettings().first;
      if (mounted) {
        setState(() {
          _patient = p;
          _setting = s;
          _loading = false;
        });
      }
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
                    Icons.timeline_outlined,
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

          // ← هنا التايم لاين بدل القائمة العادية
          return SingleChildScrollView(
            child: MedicalTimeline(
              visits: state.visits,
              patient: _patient!,
              setting: _setting,
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showAddVisit(BuildContext context) {
    final authState = getIt<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    // احصل على الـ Cubit قبل ما تفتح الـ Dialog
    final visitsCubit = context.read<VisitsCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddVisitDialog(
        doctorId: authState.user.id,
        patientName: _patient!.fullName,
        visitsCubit: visitsCubit, // ← مرره مباشرة
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

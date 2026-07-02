import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables/patients_table.dart';
import '../../../data/repositories/patients_repository.dart';
import '../cubit/patients_cubit.dart';
import '../cubit/patients_state.dart';
import '../widgets/patient_form_dialog.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatientsCubit(getIt<PatientsRepository>()),
      child: const _PatientsView(),
    );
  }
}

class _PatientsView extends StatefulWidget {
  const _PatientsView();

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                  'المرضى',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3864),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showPatientForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مريض'),
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

            // ── البحث ──
            TextField(
              controller: _searchController,
              onChanged: (v) => context.read<PatientsCubit>().search(v),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PatientsCubit>().search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── الجدول ──
            Expanded(
              child: BlocBuilder<PatientsCubit, PatientsState>(
                builder: (context, state) {
                  if (state is PatientsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is PatientsError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is PatientsLoaded) {
                    if (state.patients.isEmpty) {
                      return _buildEmpty();
                    }
                    return _buildTable(context, state.patients);
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مرضى بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط "إضافة مريض" لتسجيل أول مريض',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<Patient> patients) {
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
                Expanded(flex: 3, child: _HeaderCell('الاسم')),
                Expanded(flex: 1, child: _HeaderCell('الجنس')),
                Expanded(flex: 1, child: _HeaderCell('العمر')),
                Expanded(flex: 2, child: _HeaderCell('الهاتف')),
                Expanded(flex: 2, child: _HeaderCell('آخر زيارة')),
                Expanded(flex: 2, child: _HeaderCell('إجراءات')),
              ],
            ),
          ),
          // صفوف البيانات
          Expanded(
            child: ListView.separated(
              itemCount: patients.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                return _PatientRow(
                  patient: patients[index],
                  onEdit: () =>
                      _showPatientForm(context, patient: patients[index]),
                  onArchive: () => _confirmArchive(context, patients[index]),
                );
              },
            ),
          ),

          // تذييل: عدد المرضى
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Text(
                  'إجمالي المرضى: ${patients.length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientForm(BuildContext context, {Patient? patient}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<PatientsCubit>(),
        child: PatientFormDialog(patient: patient),
      ),
    );
  }

  void _confirmArchive(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أرشفة المريض'),
        content: Text(
          'هل تريد أرشفة "${patient.fullName}"؟\n'
          'ستختفي من القائمة لكن بياناتها تبقى محفوظة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context.read<PatientsCubit>().archivePatient(
                patient.id,
              );
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('أرشفة'),
          ),
        ],
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

// ── صف مريض ──
class _PatientRow extends StatelessWidget {
  final Patient patient;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _PatientRow({
    required this.patient,
    required this.onEdit,
    required this.onArchive,
  });

  String _calcAge() {
    if (patient.birthDate != null) {
      final age = DateTime.now().difference(patient.birthDate!).inDays ~/ 365;
      return '$age سنة';
    }
    if (patient.manualAge != null) return '${patient.manualAge} سنة';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // الاسم
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1F3864).withOpacity(0.1),
                  child: Text(
                    patient.fullName.isNotEmpty ? patient.fullName[0] : '?',
                    style: const TextStyle(
                      color: Color(0xFF1F3864),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    patient.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // الجنس
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(
                  patient.gender == Gender.male ? Icons.male : Icons.female,
                  size: 16,
                  color: patient.gender == Gender.male
                      ? Colors.blue
                      : Colors.pink,
                ),
                const SizedBox(width: 4),
                Text(
                  patient.gender == Gender.male ? 'ذكر' : 'أنثى',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          // العمر
          Expanded(
            flex: 1,
            child: Text(_calcAge(), style: const TextStyle(fontSize: 13)),
          ),
          // الهاتف
          Expanded(
            flex: 2,
            child: Text(
              patient.phone,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
          // آخر زيارة
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(patient.updatedAt),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          // الأزرار
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF1F3864),
                  tooltip: 'تعديل',
                  onTap: onEdit,
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.archive_outlined,
                  color: Colors.orange,
                  tooltip: 'أرشفة',
                  onTap: onArchive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

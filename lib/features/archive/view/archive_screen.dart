import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injector.dart';
import '../../../core/router/app_router.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables/patients_table.dart';
import '../../../data/repositories/patients_repository.dart';

// ── State ──
abstract class ArchiveState {}

class ArchiveLoading extends ArchiveState {}

class ArchiveLoaded extends ArchiveState {
  final List<Patient> patients;
  ArchiveLoaded(this.patients);
}

class ArchiveError extends ArchiveState {
  final String message;
  ArchiveError(this.message);
}

// ── Cubit ──
class ArchiveCubit extends Cubit<ArchiveState> {
  final PatientsRepository repository;

  ArchiveCubit(this.repository) : super(ArchiveLoading()) {
    _listen();
  }

  void _listen() {
    repository.watchArchivedPatients().listen(
      (list) {
        if (!isClosed) emit(ArchiveLoaded(list));
      },
      onError: (e) {
        if (!isClosed) emit(ArchiveError(e.toString()));
      },
    );
  }

  Future<String?> restorePatient(int id) async {
    try {
      await repository.restorePatient(id);
      return null;
    } catch (e) {
      return 'فشل الاستعادة: $e';
    }
  }
}

// ── Screen ──
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArchiveCubit(getIt<PatientsRepository>()),
      child: const _ArchiveView(),
    );
  }
}

class _ArchiveView extends StatefulWidget {
  const _ArchiveView();

  @override
  State<_ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends State<_ArchiveView> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
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
            _buildHeader(),
            const SizedBox(height: 24),

            // ── إحصائية ──
            BlocBuilder<ArchiveCubit, ArchiveState>(
              builder: (context, state) {
                if (state is! ArchiveLoaded) return const SizedBox();
                return _buildStatBanner(state.patients.length);
              },
            ),
            const SizedBox(height: 20),

            // ── البحث ──
            _buildSearchBar(),
            const SizedBox(height: 20),

            // ── القائمة ──
            Expanded(
              child: BlocBuilder<ArchiveCubit, ArchiveState>(
                builder: (context, state) {
                  if (state is ArchiveLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ArchiveError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is ArchiveLoaded) {
                    final filtered = _filterPatients(state.patients);
                    if (state.patients.isEmpty) {
                      return _buildEmptyAll();
                    }
                    if (filtered.isEmpty) {
                      return _buildEmptySearch();
                    }
                    return _buildGrid(context, filtered);
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F3864), Color(0xFF2E75B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأرشيف',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F3864),
              ),
            ),
            Text(
              'ملفات المرضى المؤرشفة',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3864), Color(0xFF2E75B6)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.archive_rounded, color: Colors.white70, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count مريض مؤرشف',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'يمكن استعادة أي ملف في أي وقت',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 14),
                SizedBox(width: 6),
                Text(
                  'البيانات محفوظة ولا تُحذف نهائياً',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _search = v),
      decoration: InputDecoration(
        hintText: 'ابحث بالاسم أو رقم الهاتف...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
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
    );
  }

  List<Patient> _filterPatients(List<Patient> patients) {
    if (_search.trim().isEmpty) return patients;
    final kw = _search.trim().toLowerCase();
    return patients
        .where(
          (p) => p.fullName.toLowerCase().contains(kw) || p.phone.contains(kw),
        )
        .toList();
  }

  Widget _buildGrid(BuildContext context, List<Patient> patients) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: patients.length,
      itemBuilder: (context, i) => _ArchiveCard(
        patient: patients[i],
        onRestore: () => _confirmRestore(context, patients[i]),
        onView: () => context.go(AppRoutes.patientFile(patients[i].id)),
      ),
    );
  }

  Widget _buildEmptyAll() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[350],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'الأرشيف فارغ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الملفات المؤرشفة من شاشة المرضى ستظهر هنا',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج لـ "$_search"',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restore_rounded, color: Colors.green),
            ),
            const SizedBox(width: 10),
            const Text('استعادة المريض'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              const TextSpan(text: 'هل تريد استعادة ملف '),
              TextSpan(
                text: patient.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '؟\nسيعود للظهور في قائمة المرضى.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context.read<ArchiveCubit>().restorePatient(
                patient.id,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? 'تمت استعادة ${patient.fullName} بنجاح ✓',
                    ),
                    backgroundColor: error != null ? Colors.red : Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('استعادة'),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة المريض المؤرشف ──
class _ArchiveCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback onRestore;
  final VoidCallback onView;

  const _ArchiveCard({
    required this.patient,
    required this.onRestore,
    required this.onView,
  });

  @override
  State<_ArchiveCard> createState() => _ArchiveCardState();
}

class _ArchiveCardState extends State<_ArchiveCard> {
  bool _hovered = false;

  String _calcAge() {
    if (widget.patient.birthDate != null) {
      final age =
          DateTime.now().difference(widget.patient.birthDate!).inDays ~/ 365;
      return '$age سنة';
    }
    if (widget.patient.manualAge != null) {
      return '${widget.patient.manualAge} سنة';
    }
    return '—';
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

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final isMale = p.gender == Gender.male;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF2E75B6).withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0xFF1F3864).withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _hovered ? 16 : 8,
              offset: Offset(0, _hovered ? 6 : 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الصف الأول: أفاتار + اسم + بادج ──
              Row(
                children: [
                  // الأفاتار
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMale
                            ? [const Color(0xFF1F3864), const Color(0xFF2E75B6)]
                            : [Colors.pink.shade300, Colors.pink.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        p.fullName.isNotEmpty ? p.fullName[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // الاسم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${isMale ? 'ذكر' : 'أنثى'} • ${_calcAge()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // بادج مؤرشف
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'مؤرشف',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 10),

              // ── الصف الثاني: رقم الهاتف + تاريخ الأرشفة ──
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    p.phone,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'أُرشف: ${_formatDate(p.updatedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),

              const Spacer(),

              // ── الصف الثالث: الأزرار ──
              Row(
                children: [
                  // عرض الملف
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onView,
                      icon: const Icon(Icons.folder_open_outlined, size: 14),
                      label: const Text(
                        'الملف',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F3864),
                        side: BorderSide(
                          color: const Color(0xFF1F3864).withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // استعادة
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onRestore,
                      icon: const Icon(Icons.restore_rounded, size: 14),
                      label: const Text(
                        'استعادة',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

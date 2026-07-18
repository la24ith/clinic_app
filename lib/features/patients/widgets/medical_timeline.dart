import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/database/database.dart';
import '../../../core/services/prescription_service.dart';
import '../../../core/services/whatsapp_service.dart';

enum VisitFilter { all, chronic, acute, followup }

class MedicalTimeline extends StatefulWidget {
  final List<Visit> visits;
  final Patient patient;
  final ClinicSetting? setting;

  const MedicalTimeline({
    super.key,
    required this.visits,
    required this.patient,
    required this.setting,
  });

  @override
  State<MedicalTimeline> createState() => _MedicalTimelineState();
}

class _MedicalTimelineState extends State<MedicalTimeline> {
  final Set<int> _expanded = {};
  VisitFilter _filter = VisitFilter.all;

  // ألوان حسب نوع الزيارة (لاحقاً ممكن تضيف حقل type للجدول)
  // حالياً بنستنتجها من التشخيص أو نخليها موحدة
  Color _dotColor(int index) {
    const colors = [
      Color(0xFF6366F1), // بنفسجي
      Color(0xFF1F3864), // كحلي
      Color(0xFF10B981), // أخضر
      Color(0xFFF59E0B), // برتقالي
      Color(0xFFEF4444), // أحمر
      Color(0xFF8B5CF6), // بنفسجي فاتح
      Color(0xFF3B82F6), // أزرق
    ];
    return colors[index % colors.length];
  }

  Color _dotBg(Color c) => c.withOpacity(0.1);

  List<Visit> get _filtered {
    // حالياً كل الزيارات (لاحقاً لما تضيف حقل type بالجدول)
    return widget.visits;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStats(),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 16),
        _buildTimeline(),
      ],
    );
  }

  // ── الإحصائيات ──
  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: widget.visits.length.toString(),
            label: 'إجمالي الزيارات',
            color: const Color(0xFF1F3864),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: widget.visits.isEmpty
                ? '—'
                : _formatYear(widget.visits.first.visitDate),
            label: 'آخر زيارة',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: _formatYear(
              widget.visits.isEmpty
                  ? DateTime.now()
                  : widget.visits.last.visitDate,
            ),
            label: 'أول زيارة',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  // ── الفلاتر ──
  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            count: widget.visits.length,
            active: _filter == VisitFilter.all,
            onTap: () => setState(() => _filter = VisitFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'هذه السنة',
            count: widget.visits
                .where((v) => v.visitDate.year == DateTime.now().year)
                .length,
            active: _filter == VisitFilter.chronic,
            onTap: () => setState(() => _filter = VisitFilter.chronic),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'السنة الماضية',
            count: widget.visits
                .where((v) => v.visitDate.year == DateTime.now().year - 1)
                .length,
            active: _filter == VisitFilter.acute,
            onTap: () => setState(() => _filter = VisitFilter.acute),
          ),
        ],
      ),
    );
  }

  // ── التايم لاين ──
  Widget _buildTimeline() {
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.timeline_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'لا توجد زيارات',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // تجميع الزيارات حسب السنة
    final grouped = <int, List<_IndexedVisit>>{};
    for (int i = 0; i < _filtered.length; i++) {
      final year = _filtered[i].visitDate.year;
      grouped.putIfAbsent(year, () => []);
      grouped[year]!.add(_IndexedVisit(_filtered[i], i));
    }

    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: years.length,
      itemBuilder: (context, yi) {
        final year = years[yi];
        final yearVisits = grouped[year]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // فاصل السنة
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F3864).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1F3864).withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      year.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3864),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(color: Colors.grey.shade200, height: 1),
                  ),
                ],
              ),
            ),
            // زيارات هذه السنة
            ...yearVisits.asMap().entries.map((entry) {
              final iv = entry.value;
              final isLast =
                  entry.key == yearVisits.length - 1 && yi == years.length - 1;
              return _buildVisitItem(iv.visit, iv.index, isLast);
            }),
          ],
        );
      },
    );
  }

  // ── عنصر زيارة واحدة ──
  Widget _buildVisitItem(Visit visit, int index, bool isLast) {
    final color = _dotColor(index);
    final bg = _dotBg(color);
    final isOpen = _expanded.contains(visit.id);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الخط والنقطة
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 14,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // البطاقة
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, right: 4),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (isOpen) {
                    _expanded.remove(visit.id);
                  } else {
                    _expanded.add(visit.id);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOpen
                          ? color.withOpacity(0.4)
                          : Colors.grey.shade200,
                      width: isOpen ? 1.5 : 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الرأس دائماً ظاهر
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    visit.diagnosis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    visit.complaint,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: isOpen ? null : 1,
                                    overflow: isOpen
                                        ? null
                                        : TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDate(visit.visitDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedRotation(
                                  turns: isOpen ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // التفاصيل — تظهر عند الفتح
                      AnimatedCrossFade(
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: _buildExpandedContent(visit, color),
                        crossFadeState: isOpen
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── محتوى موسّع ──
  Widget _buildExpandedContent(Visit visit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: Colors.grey.shade100),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الشكوى
              _DetailSection(
                icon: Icons.sick_outlined,
                title: 'الشكوى',
                content: visit.complaint,
                color: color,
              ),
              const SizedBox(height: 10),

              // التشخيص
              _DetailSection(
                icon: Icons.biotech_outlined,
                title: 'التشخيص',
                content: visit.diagnosis,
                color: color,
              ),
              const SizedBox(height: 10),

              // العلاج
              _DetailSection(
                icon: Icons.medication_outlined,
                title: 'العلاج / الوصفة',
                content: visit.treatment,
                color: const Color(0xFF10B981),
                highlight: true,
              ),

              // الملاحظات
              if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailSection(
                  icon: Icons.notes_outlined,
                  title: 'ملاحظات',
                  content: visit.notes!,
                  color: const Color(0xFFF59E0B),
                ),
              ],

              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 10),

              // أزرار الطباعة والمشاركة
              Row(
                children: [
                  _ActionBtn(
                    icon: Icons.print_outlined,
                    label: 'طباعة الوصفة',
                    color: const Color(0xFF1F3864),
                    onTap: () => _print(visit),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.share_outlined,
                    label: 'واتساب',
                    color: const Color(0xFF25D366),
                    onTap: () => _share(visit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _print(Visit visit) async {
    try {
      await PrescriptionService.printPrescription(
        visit: visit,
        patient: widget.patient,
        setting:
            widget.setting ??
            const ClinicSetting(id: 1, autoBackupEnabled: false),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الطباعة: $e')));
      }
    }
  }

  Future<void> _share(Visit visit) async {
    // إظهار Loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('جاري تجهيز الوصفة...'),
            ],
          ),
          duration: Duration(seconds: 15),
        ),
      );
    }

    final result = await WhatsAppService.sharePresciption(
      visit: visit,
      patient: widget.patient,
      setting:
          widget.setting ??
          const ClinicSetting(id: 1, autoBackupEnabled: false),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result.isSuccess && result.isDesktop) {
      // Dialog يشرح الخطوات
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share_outlined,
                  color: Color(0xFF25D366),
                ),
              ),
              const SizedBox(width: 10),
              const Text('إرسال الوصفة عبر واتساب'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الخطوات
              _buildStep(1, 'تم فتح مجلد الوصفة تلقائياً', done: true),
              const SizedBox(height: 10),
              _buildStep(2, 'تم فتح واتساب مع الرسالة', done: true),
              const SizedBox(height: 10),
              _buildStep(3, 'اضغط أيقونة المرفق في واتساب', done: false),
              const SizedBox(height: 10),
              _buildStep(4, 'اختر الملف من المجلد المفتوح', done: false),
              const SizedBox(height: 16),

              // مسار الملف
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: Color(0xFF1F3864),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.pdfPath ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // زر نسخ المسار
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 14),
                      tooltip: 'نسخ المسار',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: result.pdfPath ?? ''),
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ المسار ✓'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تم'),
            ),
          ],
        ),
      );
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildStep(int num, String text, {required bool done}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF25D366)
                : const Color(0xFF1F3864).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    num.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3864),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: done ? Colors.green[700] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatYear(DateTime d) => d.year.toString();
}

// ── Model مساعد ──
class _IndexedVisit {
  final Visit visit;
  final int index;
  _IndexedVisit(this.visit, this.index);
}

// ── بطاقة إحصائية ──
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── شريحة فلتر ──
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1F3864) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF1F3864) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : Colors.grey[700],
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: active ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── قسم تفصيلي ──
class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final bool highlight;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(highlight ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(8),
        border: highlight ? Border.all(color: color.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ── زر إجراء ──
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

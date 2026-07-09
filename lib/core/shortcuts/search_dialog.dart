import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/database.dart';
import '../../data/repositories/patients_repository.dart';
import '../router/app_router.dart';

class SearchDialog extends StatefulWidget {
  final PatientsRepository repository;
  const SearchDialog({super.key, required this.repository});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final _ctrl = TextEditingController();
  List<Patient> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String kw) async {
    if (kw.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await widget.repository.searchPatients(kw).first;
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── حقل البحث ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1F3864),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _search,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مريض بالاسم أو الهاتف...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            // ── النتائج ──
            if (_results.isEmpty && _ctrl.text.length >= 2)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد نتائج',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else if (_results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'اكتب اسم المريض أو رقم هاتفه',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ctrl+F للبحث السريع من أي شاشة',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, i) {
                    final p = _results[i];
                    return _SearchResultTile(
                      patient: p,
                      searchTerm: _ctrl.text,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.patientFile(p.id));
                      },
                    );
                  },
                ),
              ),

            // ── تذييل: مفاتيح الاختصارات ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  _ShortcutHint(key_: 'Ctrl+W', label: 'قائمة الانتظار'),
                  const SizedBox(width: 16),
                  _ShortcutHint(key_: 'Ctrl+N', label: 'مريض جديد'),
                  const SizedBox(width: 16),
                  _ShortcutHint(key_: 'Ctrl+M', label: 'موعد جديد'),
                  const SizedBox(width: 16),
                  _ShortcutHint(key_: 'Ctrl+F', label: 'بحث'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── نتيجة بحث واحدة مع تمييز النص ──
class _SearchResultTile extends StatelessWidget {
  final Patient patient;
  final String searchTerm;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.patient,
    required this.searchTerm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1F3864).withOpacity(0.1),
        child: Text(
          patient.fullName.isNotEmpty ? patient.fullName[0] : '?',
          style: const TextStyle(
            color: Color(0xFF1F3864),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: _HighlightText(
        text: patient.fullName,
        highlight: searchTerm,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.phone_outlined, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          _HighlightText(
            text: patient.phone,
            highlight: searchTerm,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1F3864).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'فتح الملف',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF1F3864),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

// ── تمييز النص المبحوث عنه ──
class _HighlightText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? style;

  const _HighlightText({
    required this.text,
    required this.highlight,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.trim().isEmpty) {
      return Text(text, style: style);
    }

    final lower = text.toLowerCase();
    final hlLower = highlight.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(hlLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + highlight.length),
          style: (style ?? const TextStyle()).copyWith(
            color: const Color(0xFF1F3864),
            fontWeight: FontWeight.bold,
            backgroundColor: const Color(0xFF1F3864).withOpacity(0.12),
          ),
        ),
      );
      start = idx + highlight.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── تلميح الاختصار ──
class _ShortcutHint extends StatelessWidget {
  final String key_;
  final String label;

  const _ShortcutHint({required this.key_, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 1),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            key_,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

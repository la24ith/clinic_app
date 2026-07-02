import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/waiting_list_repository.dart';
import '../cubit/waiting_list_cubit.dart';

class AddToWaitingDialog extends StatefulWidget {
  final WaitingListRepository repository;
  const AddToWaitingDialog({super.key, required this.repository});

  @override
  State<AddToWaitingDialog> createState() => _AddToWaitingDialogState();
}

class _AddToWaitingDialogState extends State<AddToWaitingDialog> {
  final _searchCtrl = TextEditingController();
  List<Patient> _results = [];
  Patient? _selected;
  bool _isSearching = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await widget.repository.searchPatients(keyword);
    if (mounted)
      setState(() {
        _results = results;
        _isSearching = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إضافة مريض لقائمة الانتظار',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3864),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 20),

              // البحث
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو رقم الهاتف...',
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // نتائج البحث
              if (_results.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      final p = _results[i];
                      final isSelected = _selected?.id == p.id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: const Color(
                          0xFF1F3864,
                        ).withOpacity(0.08),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF1F3864,
                          ).withOpacity(0.1),
                          child: Text(
                            p.fullName.isNotEmpty ? p.fullName[0] : '?',
                            style: const TextStyle(
                              color: Color(0xFF1F3864),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(p.fullName),
                        subtitle: Text(p.phone),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1F3864),
                              )
                            : null,
                        onTap: () => setState(() => _selected = p),
                      );
                    },
                  ),
                ),

              if (_selected != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3864).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1F3864).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_pin_rounded,
                        color: Color(0xFF1F3864),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selected!.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F3864),
                            ),
                          ),
                          Text(
                            _selected!.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'تم الاختيار ✓',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // الأزرار
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: (_selected == null || _isSaving) ? null : _onAdd,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAdd() async {
    if (_selected == null) return;
    setState(() => _isSaving = true);

    final error = await context.read<WaitingListCubit>().addPatientToWaiting(
      _selected!.id,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'تمت إضافة ${_selected!.fullName} لقائمة الانتظار',
        ),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ),
    );
  }
}

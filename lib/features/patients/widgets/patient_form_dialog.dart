import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables/patients_table.dart';
import '../cubit/patients_cubit.dart';

class PatientFormDialog extends StatefulWidget {
  final Patient? patient; // null = إضافة، غير null = تعديل

  const PatientFormDialog({super.key, this.patient});

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;
  late Gender _gender;
  bool _isSaving = false;

  bool get isEdit => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _ageCtrl = TextEditingController(text: p?.manualAge?.toString() ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _gender = p?.gender ?? Gender.male;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'تعديل بيانات المريض' : 'إضافة مريض جديد',
                      style: const TextStyle(
                        fontSize: 18,
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
                const Divider(height: 24),

                // الاسم
                _buildField(
                  controller: _nameCtrl,
                  label: 'الاسم الكامل *',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الاسم إلزامي' : null,
                ),
                const SizedBox(height: 14),

                // الجنس
                Row(
                  children: [
                    const Text(
                      'الجنس:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('ذكر'),
                      selected: _gender == Gender.male,
                      onSelected: (_) => setState(() => _gender = Gender.male),
                      selectedColor: const Color(0xFF1F3864).withOpacity(0.15),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('أنثى'),
                      selected: _gender == Gender.female,
                      onSelected: (_) =>
                          setState(() => _gender = Gender.female),
                      selectedColor: Colors.pink.withOpacity(0.15),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // الهاتف والعمر في صف
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildField(
                        controller: _phoneCtrl,
                        label: 'الهاتف *',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 7)
                            ? 'رقم هاتف غير صحيح'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildField(
                        controller: _ageCtrl,
                        label: 'العمر',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // العنوان
                _buildField(
                  controller: _addressCtrl,
                  label: 'العنوان',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),

                // ملاحظات
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: _decoration('ملاحظات', Icons.notes_outlined),
                ),
                const SizedBox(height: 24),

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
                      onPressed: _isSaving ? null : _onSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F3864),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
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
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decoration(label, icon),
      validator: validator,
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final cubit = context.read<PatientsCubit>();
    String? error;

    if (isEdit) {
      final updated = widget.patient!.copyWith(
        fullName: _nameCtrl.text.trim(),
        gender: _gender,
        phone: _phoneCtrl.text.trim(),
        manualAge: Value(int.tryParse(_ageCtrl.text)),
        address: Value(
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        ),
        notes: Value(
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
        updatedAt: DateTime.now(),
      );
      error = await cubit.updatePatient(updated);
    } else {
      error = await cubit.addPatient(
        fullName: _nameCtrl.text.trim(),
        gender: _gender,
        phone: _phoneCtrl.text.trim(),
        manualAge: int.tryParse(_ageCtrl.text),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'تم تعديل البيانات' : 'تمت إضافة المريض'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

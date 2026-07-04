import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/visits_cubit.dart';

class AddVisitDialog extends StatefulWidget {
  final int doctorId;
  final String patientName;

  const AddVisitDialog({
    super.key,
    required this.doctorId,
    required this.patientName,
  });

  @override
  State<AddVisitDialog> createState() => _AddVisitDialogState();
}

class _AddVisitDialogState extends State<AddVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _complaintCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _complaintCtrl.dispose();
    _diagnosisCtrl.dispose();
    _treatmentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 580,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إضافة زيارة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F3864),
                          ),
                        ),
                        Text(
                          widget.patientName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // الشكوى
                _buildField(
                  controller: _complaintCtrl,
                  label: 'الشكوى (يشكو من...) *',
                  icon: Icons.sick_outlined,
                  minLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الشكوى إلزامية' : null,
                ),
                const SizedBox(height: 14),

                // التشخيص
                _buildField(
                  controller: _diagnosisCtrl,
                  label: 'التشخيص *',
                  icon: Icons.biotech_outlined,
                  minLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'التشخيص إلزامي' : null,
                ),
                const SizedBox(height: 14),

                // العلاج
                _buildField(
                  controller: _treatmentCtrl,
                  label: 'العلاج / الوصفة *',
                  icon: Icons.medication_outlined,
                  minLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'العلاج إلزامي' : null,
                ),
                const SizedBox(height: 14),

                // ملاحظات
                _buildField(
                  controller: _notesCtrl,
                  label: 'ملاحظات وتعليمات',
                  icon: Icons.notes_outlined,
                  minLines: 2,
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
                      label: const Text('حفظ الزيارة'),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int minLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines + 2,
      decoration: InputDecoration(
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
      ),
      validator: validator,
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final error = await context.read<VisitsCubit>().addVisit(
      doctorId: widget.doctorId,
      complaint: _complaintCtrl.text.trim(),
      diagnosis: _diagnosisCtrl.text.trim(),
      treatment: _treatmentCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'تم حفظ الزيارة بنجاح'),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ),
    );
  }
}

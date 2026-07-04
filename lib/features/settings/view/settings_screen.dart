import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/di/injector.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../features/auth/cubit/auth_cubit.dart';
import '../../../features/auth/cubit/auth_state.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(getIt<SettingsRepository>()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading || state is SettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsError) {
            return Center(child: Text(state.message));
          }

          final setting = state is SettingsLoaded
              ? state.setting
              : (state as SettingsSaved).setting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الإعدادات',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3864),
                  ),
                ),
                const SizedBox(height: 24),

                // قسم معلومات العيادة
                _ClinicInfoSection(setting: setting),
                const SizedBox(height: 20),

                // قسم معلومات الطباعة
                _PrintingSection(setting: setting),
                const SizedBox(height: 20),

                // قسم النسخ الاحتياطي
                _BackupSection(setting: setting),
                const SizedBox(height: 20),

                // قسم الحساب
                _AccountSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── قسم معلومات العيادة ──
class _ClinicInfoSection extends StatefulWidget {
  final ClinicSetting setting;
  const _ClinicInfoSection({required this.setting});

  @override
  State<_ClinicInfoSection> createState() => _ClinicInfoSectionState();
}

class _ClinicInfoSectionState extends State<_ClinicInfoSection> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.setting.doctorName ?? '');
    _specCtrl = TextEditingController(text: widget.setting.specialty ?? '');
    _phoneCtrl = TextEditingController(text: widget.setting.clinicPhone ?? '');
    _addressCtrl = TextEditingController(
      text: widget.setting.clinicAddress ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'معلومات العيادة',
      icon: Icons.local_hospital_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _nameCtrl,
                  label: 'اسم الطبيب',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _Field(
                  controller: _specCtrl,
                  label: 'الاختصاص',
                  icon: Icons.medical_services_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _phoneCtrl,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _Field(
                  controller: _addressCtrl,
                  label: 'العنوان',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
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
              label: const Text('حفظ المعلومات'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F3864),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final error = await context.read<SettingsCubit>().saveClinicInfo(
      doctorName: _nameCtrl.text.trim(),
      specialty: _specCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showSnack(context, error);
  }
}

// ── قسم معلومات الطباعة ──
class _PrintingSection extends StatelessWidget {
  final ClinicSetting setting;
  const _PrintingSection({required this.setting});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'معلومات الطباعة',
      icon: Icons.print_outlined,
      child: Column(
        children: [
          _ImagePicker(
            label: 'شعار العيادة',
            hint: 'يظهر في رأس الوصفة المطبوعة',
            imagePath: setting.logoPath,
            onPick: (path) => context.read<SettingsCubit>().saveLogo(path),
          ),
          const Divider(height: 24),
          _ImagePicker(
            label: 'الختم',
            hint: 'يظهر في تذييل الوصفة (PNG بخلفية شفافة)',
            imagePath: setting.stampPath,
            onPick: (path) => context.read<SettingsCubit>().saveStamp(path),
          ),
          const Divider(height: 24),
          _ImagePicker(
            label: 'التوقيع',
            hint: 'يظهر في تذييل الوصفة (PNG بخلفية شفافة)',
            imagePath: setting.signaturePath,
            onPick: (path) => context.read<SettingsCubit>().saveSignature(path),
          ),
        ],
      ),
    );
  }
}

// ── قسم النسخ الاحتياطي ──
class _BackupSection extends StatefulWidget {
  final ClinicSetting setting;
  const _BackupSection({required this.setting});

  @override
  State<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<_BackupSection> {
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.setting;

    return _SectionCard(
      title: 'النسخ الاحتياطي',
      icon: Icons.backup_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // آخر نسخة احتياطية
          if (s.lastBackupAt != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'آخر نسخة احتياطية: ${_formatDate(s.lastBackupAt!)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (s.lastBackupAt != null) const SizedBox(height: 14),

          // مسار النسخ الاحتياطي
          if (s.backupFolderPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: Color(0xFF1F3864),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      s.backupFolderPath!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // أزرار
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _isBackingUp ? null : _pickFolder,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('تحديد مجلد الحفظ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F3864),
                  side: const BorderSide(color: Color(0xFF1F3864)),
                ),
              ),
              FilledButton.icon(
                onPressed: (_isBackingUp || s.backupFolderPath == null)
                    ? null
                    : _backupNow,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.backup_outlined),
                label: const Text('نسخة احتياطية الآن'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3864),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'اختر مجلد النسخ الاحتياطي',
    );
    if (path != null && mounted) {
      final error = await context.read<SettingsCubit>().updateBackupSettings(
        enabled: true,
        folder: path,
      );
      if (mounted) _showSnack(context, error);
    }
  }

  Future<void> _backupNow() async {
    final folder = widget.setting.backupFolderPath;
    if (folder == null) return;
    setState(() => _isBackingUp = true);
    final error = await context.read<SettingsCubit>().backupNow(folder);
    if (!mounted) return;
    setState(() => _isBackingUp = false);
    _showSnack(context, error, successMessage: 'تمت النسخة الاحتياطية بنجاح ✓');
  }

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }
}

// ── قسم الحساب ──
class _AccountSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = getIt<AuthCubit>().state;
    final name = authState is AuthSuccess ? authState.user.fullName : '—';
    final role = authState is AuthSuccess
        ? (authState.user.role.name == 'doctor' ? 'طبيب' : 'مساعد')
        : '—';

    return _SectionCard(
      title: 'الحساب',
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          // بيانات المستخدم الحالي
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F3864).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF1F3864),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // زر تغيير كلمة المرور
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () {
                if (authState is! AuthSuccess) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChangePasswordScreen(userId: authState.user.id),
                  ),
                );
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text('تغيير كلمة المرور'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F3864),
                side: const BorderSide(color: Color(0xFF1F3864)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── مكوّن اختيار الصورة ──
class _ImagePicker extends StatelessWidget {
  final String label;
  final String hint;
  final String? imagePath;
  final Future<String?> Function(String) onPick;

  const _ImagePicker({
    required this.label,
    required this.hint,
    required this.imagePath,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // معاينة الصورة
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade50,
          ),
          child: imagePath != null && File(imagePath!).existsSync()
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.file(File(imagePath!), fit: BoxFit.contain),
                )
              : Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
        ),
        const SizedBox(width: 14),

        // النص والزر
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                hint,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.image,
                    dialogTitle: 'اختر $label',
                  );
                  if (result != null &&
                      result.files.single.path != null &&
                      context.mounted) {
                    final error = await onPick(result.files.single.path!);
                    if (context.mounted) _showSnack(context, error);
                  }
                },
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: Text('رفع $label'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F3864),
                  side: const BorderSide(color: Color(0xFF1F3864), width: 0.8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── بطاقة قسم عامة ──
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3864).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF1F3864), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3864),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── حقل نص مساعد ──
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
    );
  }
}

void _showSnack(
  BuildContext context,
  String? error, {
  String successMessage = 'تم الحفظ بنجاح',
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error ?? successMessage),
      backgroundColor: error != null ? Colors.red : Colors.green,
    ),
  );
}

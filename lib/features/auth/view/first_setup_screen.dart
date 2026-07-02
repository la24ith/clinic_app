import 'package:clinic_app/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class FirstSetupScreen extends StatefulWidget {
  const FirstSetupScreen({super.key});

  @override
  State<FirstSetupScreen> createState() => _FirstSetupScreenState();
}

class _FirstSetupScreenState extends State<FirstSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _specController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _userController.dispose();
    _passController.dispose();
    _specController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        if (state is AuthSuccess) {
          context.go(AppRoutes.dashboard); // ← هاد الناقص
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'مرحباً ${state.user.fullName}! تم إنشاء الحساب بنجاح 🎉',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 460,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 56,
                            color: Color(0xFF1F3864),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'الإعداد الأولي للنظام',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F3864),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'أنشئ حساب الطبيب الرئيسي (سيتم هذا مرة واحدة فقط)',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildField(
                          controller: _nameController,
                          label: 'اسم الطبيب الكامل *',
                          icon: Icons.person,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'هذا الحقل إلزامي'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _specController,
                          label: 'الاختصاص',
                          icon: Icons.medical_services_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _userController,
                          label: 'اسم المستخدم *',
                          icon: Icons.badge_outlined,
                          isLtr: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'هذا الحقل إلزامي';
                            }
                            if (v.trim().length < 3) {
                              return 'يجب أن يكون 3 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passController,
                          textDirection: TextDirection.ltr,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'هذا الحقل إلزامي';
                            }
                            if (v.length < 6) {
                              return 'يجب أن تكون 6 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: isLoading ? null : _onSubmit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F3864),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: const Text(
                                  'إنشاء الحساب والبدء',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
    bool isLtr = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: isLtr ? TextDirection.ltr : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().createFirstUser(
      username: _userController.text,
      password: _passController.text,
      fullName: _nameController.text,
      specialty: _specController.text.trim().isEmpty
          ? null
          : _specController.text,
    );
  }
}

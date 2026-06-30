import 'package:clinic_app/data/database/tables/patients_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injector.dart';
import 'data/database/database.dart';
import 'features/patients/cubit/patients_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();

  final db = getIt<AppDatabase>();
  await db.ensureSettingsRowExists();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اختبار قاعدة البيانات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        fontFamily: 'Arial',
      ),
      // اتجاه الواجهة من اليمين لليسار (مهم للعربية)
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: BlocProvider(
        create: (_) => PatientsCubit(getIt())
          ..addPatient(
            fullName: '',
            gender: Gender.male,
            phone: '',
          ).catchError((_) {}), // تجاهل - سنحذف هذا السطر، أضيف فقط لتوضيح
        child: const PatientsTestScreen(),
      ),
    );
  }
}

class PatientsTestScreen extends StatefulWidget {
  const PatientsTestScreen({super.key});

  @override
  State<PatientsTestScreen> createState() => _PatientsTestScreenState();
}

class _PatientsTestScreenState extends State<PatientsTestScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Gender _selectedGender = Gender.male;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار قاعدة البيانات - المرضى'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- نموذج إضافة مريض تجريبي ----------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إضافة مريض تجريبي',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'الهاتف',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('الجنس:'),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('ذكر'),
                          selected: _selectedGender == Gender.male,
                          onSelected: (_) =>
                              setState(() => _selectedGender = Gender.male),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('أنثى'),
                          selected: _selectedGender == Gender.female,
                          onSelected: (_) =>
                              setState(() => _selectedGender = Gender.female),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _onAddPressed,
                      icon: const Icon(Icons.add),
                      label: const Text('حفظ المريض'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'قائمة المرضى (تتحدّث تلقائياً):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // ---------------- قائمة المرضى - Real-time ----------------
            Expanded(
              child: BlocBuilder<PatientsCubit, PatientsState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.errorMessage != null) {
                    return Center(child: Text(state.errorMessage!));
                  }
                  if (state.patients.isEmpty) {
                    return const Center(child: Text('لا يوجد مرضى بعد'));
                  }
                  return ListView.separated(
                    itemCount: state.patients.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final patient = state.patients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            patient.fullName.isNotEmpty
                                ? patient.fullName[0]
                                : '?',
                          ),
                        ),
                        title: Text(patient.fullName),
                        subtitle: Text(
                          '${patient.gender == Gender.male ? "ذكر" : "أنثى"} • ${patient.phone}',
                        ),
                        trailing: Text('#${patient.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddPressed() {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة الاسم والهاتف')),
      );
      return;
    }

    context.read<PatientsCubit>().addPatient(
      fullName: _nameController.text.trim(),
      gender: _selectedGender,
      phone: _phoneController.text.trim(),
    );

    _nameController.clear();
    _phoneController.clear();
  }
}

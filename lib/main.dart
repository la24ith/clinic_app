import 'package:flutter/material.dart';
import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'data/database/database.dart';
import 'features/auth/cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();

  final db = getIt<AppDatabase>();
  await db.ensureSettingsRowExists();

  // تحقق من الحالة الأولية قبل بدء التطبيق
  await getIt<AuthCubit>().checkInitialState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'نظام إدارة العيادة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1F3864),
        fontFamily: 'Arial',
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      routerConfig: appRouter,
    );
  }
}

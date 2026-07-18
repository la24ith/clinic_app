import 'package:clinic_app/core/di/injector.dart';
import 'package:clinic_app/core/licensing/license_manager.dart';
import 'package:clinic_app/core/router/app_router.dart';
import 'package:clinic_app/core/shortcuts/global_shortcuts_wrapper.dart';
import 'package:clinic_app/data/database/database.dart';
import 'package:clinic_app/features/auth/cubit/auth_cubit.dart';
import 'package:clinic_app/features/licensing/view/license_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();

  final db = getIt<AppDatabase>();
  await db.ensureSettingsRowExists();

  // تحقق من الترخيص عند بدء التطبيق
  final licenseInfo = await LicenseManager.check();
  await getIt<AuthCubit>().checkInitialState();

  runApp(MyApp(licenseInfo: licenseInfo));
}

class MyApp extends StatefulWidget {
  final LicenseInfo licenseInfo;
  const MyApp({super.key, required this.licenseInfo});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late LicenseInfo _licenseInfo;

  @override
  void initState() {
    super.initState();
    _licenseInfo = widget.licenseInfo;
  }

  @override
  Widget build(BuildContext context) {
    // لو انتهت الفترة التجريبية → شاشة الترخيص
    if (_licenseInfo.status == LicenseStatus.trialExpired ||
        _licenseInfo.status == LicenseStatus.expired ||
        _licenseInfo.status == LicenseStatus.invalid) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1F3864),
        ),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: LicenseScreen(
          info: _licenseInfo,
          onActivated: () async {
            final info = await LicenseManager.check();
            setState(() => _licenseInfo = info);
          },
        ),
      );
    }

    // التطبيق الطبيعي
    return MaterialApp.router(
      title: 'نظام إدارة العيادة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1F3864),
        fontFamily: 'Arial',
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: GlobalShortcutsWrapper(child: child!),
      ),
      routerConfig: appRouter,
    );
  }
}

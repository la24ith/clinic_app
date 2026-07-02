import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/users_repository.dart';
import '../../core/services/session_service.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/cubit/auth_state.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/first_setup_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/dashboard/view/dashboard_screen.dart';
import '../../features/patients/view/patients_screen.dart';
import '../../features/appointments/view/appointments_screen.dart';
import '../../features/waiting_list/view/waiting_list_screen.dart';
import '../../features/settings/view/settings_screen.dart';

// المسارات كثوابت لتجنب الأخطاء الإملائية
class AppRoutes {
  static const login = '/login';
  static const firstSetup = '/first-setup';
  static const dashboard = '/dashboard';
  static const patients = '/patients';
  static const appointments = '/appointments';
  static const waitingList = '/waiting-list';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  redirect: (context, state) async {
    // منطق إعادة التوجيه بناءً على حالة المصادقة
    final authCubit = getIt<AuthCubit>();
    final authState = authCubit.state;

    final isAuthRoute =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.firstSetup;

    if (authState is AuthFirstSetup) return AppRoutes.firstSetup;
    if (authState is AuthSuccess && isAuthRoute) return AppRoutes.dashboard;
    if (authState is! AuthSuccess && !isAuthRoute) return AppRoutes.login;

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => BlocProvider.value(
        value: getIt<AuthCubit>(),
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.firstSetup,
      builder: (context, state) => BlocProvider.value(
        value: getIt<AuthCubit>(),
        child: const FirstSetupScreen(),
      ),
    ),

    // Shell Route - القائمة الجانبية تحتضن كل الشاشات الداخلية
    ShellRoute(
      builder: (context, state, child) => BlocProvider.value(
        value: getIt<AuthCubit>(), // ← مرر الـ Cubit للـ Shell
        child: AppShell(child: child),
      ),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.patients,
          builder: (context, state) => const PatientsScreen(),
        ),
        GoRoute(
          path: AppRoutes.appointments,
          builder: (context, state) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: AppRoutes.waitingList,
          builder: (context, state) => const WaitingListScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

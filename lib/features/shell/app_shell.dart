import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injector.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/cubit/auth_state.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // القائمة الجانبية
          const _SideBar(),
          // خط فاصل
          const VerticalDivider(width: 1),
          // محتوى الشاشة الحالية
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 220,
      color: const Color(0xFF1F3864),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القائمة - اسم الطبيب
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final name = state is AuthSuccess
                  ? state.user.fullName
                  : 'العيادة';
              final specialty = state is AuthSuccess
                  ? (state.user.specialty ?? '')
                  : '';
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),

          // عناصر القائمة
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'الرئيسية',
            route: AppRoutes.dashboard,
            isActive: location == AppRoutes.dashboard,
          ),
          _NavItem(
            icon: Icons.people_rounded,
            label: 'المرضى',
            route: AppRoutes.patients,
            isActive: location == AppRoutes.patients,
          ),
          _NavItem(
            icon: Icons.calendar_month_rounded,
            label: 'المواعيد',
            route: AppRoutes.appointments,
            isActive: location == AppRoutes.appointments,
          ),
          _NavItem(
            icon: Icons.hourglass_top_rounded,
            label: 'قائمة الانتظار',
            route: AppRoutes.waitingList,
            isActive: location == AppRoutes.waitingList,
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'الأرشيف',
            route: AppRoutes.archive,
            isActive: location == AppRoutes.archive,
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'الإعدادات',
            route: AppRoutes.settings,
            isActive: location == AppRoutes.settings,
          ),

          const Spacer(),
          const Divider(color: Colors.white24, height: 1),

          // زر تسجيل الخروج
          _LogoutButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white60,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('تسجيل الخروج'),
                content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('خروج'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AuthCubit>().logout();
              if (context.mounted) context.go(AppRoutes.login);
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:clinic_app/core/di/injector.dart';
import 'package:clinic_app/core/shortcuts/app_shortcuts.dart';
import 'package:clinic_app/core/shortcuts/search_dialog.dart';
import 'package:clinic_app/data/repositories/patients_repository.dart';
import 'package:clinic_app/data/repositories/waiting_list_repository.dart';
import 'package:clinic_app/features/appointments/cubit/appointments_cubit.dart';
import 'package:clinic_app/features/appointments/widgets/add_appointment_dialog.dart';
import 'package:clinic_app/features/auth/cubit/auth_cubit.dart';
import 'package:clinic_app/features/auth/cubit/auth_state.dart';
import 'package:clinic_app/features/patients/cubit/patients_cubit.dart';
import 'package:clinic_app/features/patients/widgets/patient_form_dialog.dart';
import 'package:clinic_app/features/waiting_list/cubit/waiting_list_cubit.dart';
import 'package:clinic_app/features/waiting_list/widgets/add_to_waiting_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../router/app_router.dart'; // فيه rootNavigatorKey

class GlobalShortcutsWrapper extends StatelessWidget {
  final Widget child;
  const GlobalShortcutsWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      builder: (context, authState) {
        if (authState is! AuthSuccess) return child;

        return Shortcuts(
          shortcuts: const {
            AppShortcuts.addToWaiting: AddToWaitingIntent(),
            AppShortcuts.newPatient: NewPatientIntent(),
            AppShortcuts.newAppointment: NewAppointmentIntent(),
            AppShortcuts.search: SearchIntent(),
          },
          child: Actions(
            actions: {
              AddToWaitingIntent: CallbackAction<AddToWaitingIntent>(
                onInvoke: (_) => _openAddToWaiting(),
              ),
              NewPatientIntent: CallbackAction<NewPatientIntent>(
                onInvoke: (_) => _openNewPatient(),
              ),
              NewAppointmentIntent: CallbackAction<NewAppointmentIntent>(
                onInvoke: (_) => _openNewAppointment(),
              ),
              SearchIntent: CallbackAction<SearchIntent>(
                onInvoke: (_) => _openSearch(),
              ),
            },
            child: Focus(autofocus: true, child: child),
          ),
        );
      },
    );
  }

  // ── هلق كل ميثود بتجيب الـ context من rootNavigatorKey مش من الباراميتر ──

  void _openAddToWaiting() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AddToWaitingDialog(
        repository: getIt<WaitingListRepository>(),
        cubit: WaitingListCubit(getIt<WaitingListRepository>()),
      ),
    );
  }

  void _openNewPatient() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => PatientsCubit(getIt<PatientsRepository>()),
        child: const PatientFormDialog(),
      ),
    );
  }

  void _openNewAppointment() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AddAppointmentDialog(
        initialDate: DateTime.now(),
        repository: getIt(),
        cubit: AppointmentsCubit(repository: getIt(), waitingRepo: getIt()),
      ),
    );
  }

  void _openSearch() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (_) => SearchDialog(repository: getIt<PatientsRepository>()),
    );
  }
}

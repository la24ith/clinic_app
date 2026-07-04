import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'appointments_state.dart';
import '../../../data/database/tables/appointments_table.dart';
import '../../../data/repositories/appointments_repository.dart';
import '../../../data/repositories/waiting_list_repository.dart';

class AppointmentsCubit extends Cubit<AppointmentsState> {
  final AppointmentsRepository repository;
  final WaitingListRepository waitingRepo;
  StreamSubscription? _sub;
  DateTime _selectedDay = DateTime.now();

  AppointmentsCubit({required this.repository, required this.waitingRepo})
    : super(AppointmentsInitial()) {
    _listenToDay(_selectedDay);
  }

  void selectDay(DateTime day) {
    _selectedDay = day;
    _sub?.cancel();
    _listenToDay(day);
  }

  void _listenToDay(DateTime day) {
    emit(AppointmentsLoading());
    _sub = repository
        .watchDayWithPatients(day)
        .listen(
          (list) {
            if (!isClosed) {
              emit(AppointmentsLoaded(appointments: list, selectedDay: day));
            }
          },
          onError: (e) {
            if (!isClosed) emit(AppointmentsError(e.toString()));
          },
        );
  }

  Future<String?> addAppointment({
    required int patientId,
    required DateTime dateTime,
    String? reason,
    String? note,
  }) async {
    return repository.addAppointment(
      patientId: patientId,
      dateTime: dateTime,
      reason: reason,
      note: note,
    );
  }

  // تسجيل وصول المريض → ينقله لقائمة الانتظار تلقائياً
  Future<String?> markArrived(int appointmentId, int patientId) async {
    final err1 = await repository.updateStatus(
      appointmentId,
      AppointmentStatus.arrived,
    );
    if (err1 != null) return err1;
    return waitingRepo.addToWaiting(patientId);
  }

  Future<String?> markNoShow(int appointmentId) {
    return repository.updateStatus(appointmentId, AppointmentStatus.noShow);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

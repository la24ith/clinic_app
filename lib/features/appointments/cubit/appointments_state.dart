import '../../../data/repositories/appointments_repository.dart';

abstract class AppointmentsState {}

class AppointmentsInitial extends AppointmentsState {}

class AppointmentsLoading extends AppointmentsState {}

class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentWithPatient> appointments;
  final DateTime selectedDay;
  AppointmentsLoaded({required this.appointments, required this.selectedDay});
}

class AppointmentsError extends AppointmentsState {
  final String message;
  AppointmentsError(this.message);
}

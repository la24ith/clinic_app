import 'dart:async';
import 'package:clinic_app/data/database/tables/patients_table.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/patients_repository.dart';

class PatientsState {
  final List<Patient> patients;
  final bool isLoading;
  final String? errorMessage;

  const PatientsState({
    this.patients = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PatientsState copyWith({
    List<Patient>? patients,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PatientsCubit extends Cubit<PatientsState> {
  final PatientsRepository repository;
  StreamSubscription<List<Patient>>? _subscription;

  PatientsCubit(this.repository) : super(const PatientsState()) {
    _listenToPatients();
  }

  void _listenToPatients() {
    emit(state.copyWith(isLoading: true));
    _subscription = repository.watchAllPatients().listen(
      (patients) {
        emit(state.copyWith(patients: patients, isLoading: false));
      },
      onError: (error) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'حدث خطأ أثناء تحميل المرضى: $error',
          ),
        );
      },
    );
  }

  Future<void> addPatient({
    required String fullName,
    required Gender gender,
    required String phone,
  }) async {
    try {
      await repository.addPatient(
        fullName: fullName,
        gender: gender,
        phone: phone,
      );
      // لا حاجة لإعادة تحميل القائمة يدوياً
      // الـ Stream من Drift سينعكس تلقائياً فوراً
    } catch (error) {
      emit(state.copyWith(errorMessage: 'فشل حفظ المريض: $error'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

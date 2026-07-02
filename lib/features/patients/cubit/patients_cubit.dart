import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'patients_state.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables/patients_table.dart';
import '../../../data/repositories/patients_repository.dart';

class PatientsCubit extends Cubit<PatientsState> {
  final PatientsRepository repository;
  StreamSubscription<List<Patient>>? _sub;

  PatientsCubit(this.repository) : super(PatientsInitial()) {
    _listen('');
  }

  void search(String keyword) {
    _sub?.cancel();
    _listen(keyword);
  }

  void _listen(String keyword) {
    emit(PatientsLoading());
    final stream = keyword.trim().isEmpty
        ? repository.watchAllPatients()
        : repository.searchPatients(keyword);

    _sub = stream.listen(
      (list) {
        if (!isClosed) emit(PatientsLoaded(list));
      },
      onError: (e) {
        if (!isClosed) emit(PatientsError(e.toString()));
      },
    );
  }

  Future<String?> addPatient({
    required String fullName,
    required Gender gender,
    required String phone,
    DateTime? birthDate,
    int? manualAge,
    String? address,
    String? notes,
  }) async {
    try {
      await repository.addPatient(
        fullName: fullName,
        gender: gender,
        phone: phone,
        birthDate: birthDate,
        manualAge: manualAge,
        address: address,
        notes: notes,
      );
      return null; // نجاح
    } catch (e) {
      return 'فشل الحفظ: $e';
    }
  }

  Future<String?> updatePatient(Patient patient) async {
    try {
      await repository.updatePatient(patient);
      return null;
    } catch (e) {
      return 'فشل التعديل: $e';
    }
  }

  Future<String?> archivePatient(int id) async {
    try {
      await repository.archivePatient(id);
      return null;
    } catch (e) {
      return 'فشل الأرشفة: $e';
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

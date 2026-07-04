import 'dart:async';
import 'package:clinic_app/data/repositories/visits_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'visits_state.dart';
import '../../../data/database/database.dart';

class VisitsCubit extends Cubit<VisitsState> {
  final VisitsRepository repository;
  final int patientId;
  StreamSubscription<List<Visit>>? _sub;

  VisitsCubit(this.repository, this.patientId) : super(VisitsInitial()) {
    _listen();
  }

  void _listen() {
    emit(VisitsLoading());
    _sub = repository
        .watchVisitsForPatient(patientId)
        .listen(
          (visits) {
            if (!isClosed) emit(VisitsLoaded(visits));
          },
          onError: (e) {
            if (!isClosed) emit(VisitsError(e.toString()));
          },
        );
  }

  Future<String?> addVisit({
    required int doctorId,
    required String complaint,
    required String diagnosis,
    required String treatment,
    String? notes,
  }) async {
    return repository.addVisit(
      patientId: patientId,
      doctorId: doctorId,
      complaint: complaint,
      diagnosis: diagnosis,
      treatment: treatment,
      notes: notes,
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

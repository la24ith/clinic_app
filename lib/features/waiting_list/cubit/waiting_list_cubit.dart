import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'waiting_list_state.dart';
import '../../../data/repositories/waiting_list_repository.dart';
import '../../../data/database/tables/waiting_list_table.dart';

class WaitingListCubit extends Cubit<WaitingListState> {
  final WaitingListRepository repository;
  StreamSubscription? _sub;

  WaitingListCubit(this.repository) : super(WaitingListInitial()) {
    _listen();
  }

  void _listen() {
    emit(WaitingListLoading());
    _sub = repository.watchTodayWithPatients().listen(
      (entries) {
        if (!isClosed) emit(WaitingListLoaded(entries));
      },
      onError: (e) {
        if (!isClosed) emit(WaitingListError(e.toString()));
      },
    );
  }

  Future<String?> addPatientToWaiting(int patientId) async {
    final error = await repository.addToWaiting(patientId);
    return error;
  }

  Future<String?> updateStatus(int entryId, WaitingStatus status) async {
    return repository.updateStatus(entryId, status);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

import '../../../data/repositories/waiting_list_repository.dart';

abstract class WaitingListState {}

class WaitingListInitial extends WaitingListState {}

class WaitingListLoading extends WaitingListState {}

class WaitingListLoaded extends WaitingListState {
  final List<WaitingEntry> entries;
  WaitingListLoaded(this.entries);
}

class WaitingListError extends WaitingListState {
  final String message;
  WaitingListError(this.message);
}

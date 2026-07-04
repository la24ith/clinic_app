import '../../../data/database/database.dart';

abstract class VisitsState {}

class VisitsInitial extends VisitsState {}

class VisitsLoading extends VisitsState {}

class VisitsLoaded extends VisitsState {
  final List<Visit> visits;
  VisitsLoaded(this.visits);
}

class VisitsError extends VisitsState {
  final String message;
  VisitsError(this.message);
}

import 'dart:async';
import 'package:clinic_app/data/database/database.dart';
import 'package:clinic_app/features/dashboard/repositories/dashboard_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardState {
  final DashboardStats? stats;
  final List<WaitingListEntry> recentWaiting;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.stats,
    this.recentWaiting = const [],
    this.isLoading = true,
    this.error,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    List<WaitingListEntry>? recentWaiting,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      recentWaiting: recentWaiting ?? this.recentWaiting,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;
  StreamSubscription? _statsSub;
  StreamSubscription? _recentSub;

  DashboardCubit(this.repository) : super(const DashboardState()) {
    _init();
  }

  void _init() {
    _statsSub = repository.watchTodayStats().listen(
      (stats) {
        if (!isClosed) {
          emit(state.copyWith(stats: stats, isLoading: false));
        }
      },
      onError: (e) {
        if (!isClosed) {
          emit(state.copyWith(error: e.toString(), isLoading: false));
        }
      },
    );

    _recentSub = repository.watchRecentWaiting().listen((list) {
      if (!isClosed) emit(state.copyWith(recentWaiting: list));
    });
  }

  @override
  Future<void> close() {
    _statsSub?.cancel();
    _recentSub?.cancel();
    return super.close();
  }
}

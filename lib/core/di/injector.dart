import 'package:clinic_app/features/dashboard/repositories/dashboard_repository.dart';
import 'package:get_it/get_it.dart';
import '../../data/database/database.dart';
import '../../data/repositories/patients_repository.dart';
import '../../data/repositories/users_repository.dart';
import '../../data/repositories/waiting_list_repository.dart';
import '../services/session_service.dart';
import '../../features/auth/cubit/auth_cubit.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  getIt.registerSingleton<SessionService>(SessionService());

  getIt.registerSingleton<PatientsRepository>(
    PatientsRepository(getIt<AppDatabase>()),
  );
  getIt.registerSingleton<UsersRepository>(
    UsersRepository(getIt<AppDatabase>()),
  );
  getIt.registerSingleton<DashboardRepository>(
    DashboardRepository(getIt<AppDatabase>()),
  );
  getIt.registerSingleton<WaitingListRepository>(
    WaitingListRepository(getIt<AppDatabase>()),
  );

  getIt.registerSingleton<AuthCubit>(
    AuthCubit(
      usersRepository: getIt<UsersRepository>(),
      sessionService: getIt<SessionService>(),
    ),
  );
}

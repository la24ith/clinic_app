import 'package:get_it/get_it.dart';
import '../../data/database/database.dart';
import '../../data/repositories/patients_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  getIt.registerSingleton<PatientsRepository>(
    PatientsRepository(getIt<AppDatabase>()),
  );
}

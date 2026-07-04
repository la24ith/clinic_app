import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'settings_state.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repository;
  StreamSubscription? _sub;

  SettingsCubit(this.repository) : super(SettingsInitial()) {
    _listen();
  }

  void _listen() {
    emit(SettingsLoading());
    _sub = repository.watchSettings().listen(
      (setting) {
        if (!isClosed && setting != null) {
          emit(SettingsLoaded(setting));
        }
      },
      onError: (e) {
        if (!isClosed) emit(SettingsError(e.toString()));
      },
    );
  }

  Future<String?> saveClinicInfo({
    required String doctorName,
    required String specialty,
    required String phone,
    required String address,
  }) async {
    return repository.updateSettings(
      ClinicSettingsCompanion(
        doctorName: Value(doctorName.isEmpty ? null : doctorName),
        specialty: Value(specialty.isEmpty ? null : specialty),
        clinicPhone: Value(phone.isEmpty ? null : phone),
        clinicAddress: Value(address.isEmpty ? null : address),
      ),
    );
  }

  Future<String?> saveLogo(String sourcePath) async {
    final saved = await repository.saveImage(sourcePath, 'logo.png');
    if (saved == null) return 'فشل حفظ الشعار';
    return repository.updateSettings(
      ClinicSettingsCompanion(logoPath: Value(saved)),
    );
  }

  Future<String?> saveStamp(String sourcePath) async {
    final saved = await repository.saveImage(sourcePath, 'stamp.png');
    if (saved == null) return 'فشل حفظ الختم';
    return repository.updateSettings(
      ClinicSettingsCompanion(stampPath: Value(saved)),
    );
  }

  Future<String?> saveSignature(String sourcePath) async {
    final saved = await repository.saveImage(sourcePath, 'signature.png');
    if (saved == null) return 'فشل حفظ التوقيع';
    return repository.updateSettings(
      ClinicSettingsCompanion(signaturePath: Value(saved)),
    );
  }

  Future<String?> backupNow(String folder) {
    return repository.backupNow(folder);
  }

  Future<String?> updateBackupSettings({
    required bool enabled,
    String? folder,
  }) {
    return repository.updateSettings(
      ClinicSettingsCompanion(
        autoBackupEnabled: Value(enabled),
        backupFolderPath: Value(folder),
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

import '../../../data/database/database.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final ClinicSetting setting;
  SettingsLoaded(this.setting);
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
}

class SettingsSaving extends SettingsState {
  final ClinicSetting setting;
  SettingsSaving(this.setting);
}

class SettingsSaved extends SettingsState {
  final ClinicSetting setting;
  SettingsSaved(this.setting);
}

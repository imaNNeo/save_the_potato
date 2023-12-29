import 'package:save_the_potato/data/sources/settings_data_source.dart';

class SettingsRepository {
  SettingsRepository(this._dataSource);

  final SettingsDataSource _dataSource;

  Future<void> setAudioEnabled(bool enabled) =>
      _dataSource.setAudioEnabled(enabled);

  Future<bool> audioEnabled() => _dataSource.audioEnabled();
}

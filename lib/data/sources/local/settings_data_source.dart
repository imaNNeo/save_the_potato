import 'package:save_the_potato/data/key_value_storage.dart';

class SettingsDataSource {
  SettingsDataSource(this._storage);

  final KeyValueStorage _storage;

  Future<bool> audioEnabled() async {
    return (await _storage.getBool('audio_enabled')) ?? true;
  }

  Future<void> setAudioEnabled(bool enabled) async {
    await _storage.setBool('audio_enabled', enabled);
  }
}

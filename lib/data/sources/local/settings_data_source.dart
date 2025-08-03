import 'package:shared_preferences/shared_preferences.dart';

class SettingsDataSource {
  static const _audioEnabledKey = 'audio_enabled';
  SettingsDataSource();

  Future<bool> audioEnabled() async {
    final sharedPref = await SharedPreferences.getInstance();
    return sharedPref.getBool(_audioEnabledKey) ?? true;
  }

  Future<void> setAudioEnabled(bool enabled) async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setBool(_audioEnabledKey, enabled);
  }
}

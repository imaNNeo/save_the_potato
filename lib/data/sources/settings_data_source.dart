import 'package:shared_preferences/shared_preferences.dart';

class SettingsDataSource {
  Future<bool> audioEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('audio_enabled') ?? true;
  }

  Future<void> setAudioEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_enabled', enabled);
  }
}
